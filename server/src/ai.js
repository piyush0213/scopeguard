import { config } from './config.js';

const FALLBACK_MODELS = ['gemini-2.5-flash', 'gemini-flash-latest', 'gemini-2.5-flash-lite'];

/** Gemini-style schema (uppercase types) -> strict JSON Schema for OpenAI-compatible APIs. */
function toJsonSchema(s) {
  const type = s.type.toLowerCase();
  if (type === 'object') {
    const properties = Object.fromEntries(Object.entries(s.properties).map(([k, v]) => [k, toJsonSchema(v)]));
    return { type, properties, required: Object.keys(properties), additionalProperties: false };
  }
  if (type === 'array') return { type, items: toJsonSchema(s.items) };
  return { type };
}

function parseJson(text) {
  const clean = text.trim().replace(/^```(?:json)?\s*/i, '').replace(/```$/, '');
  try {
    return JSON.parse(clean);
  } catch {
    // Some models wrap JSON in prose: take the outermost {...}.
    const start = clean.indexOf('{');
    const end = clean.lastIndexOf('}');
    if (start === -1 || end <= start) throw new Error('Model did not return JSON');
    return JSON.parse(clean.slice(start, end + 1));
  }
}

function assertShape(obj, schema) {
  const missing = (schema.required || []).filter((k) => obj?.[k] === undefined || obj?.[k] === null);
  if (missing.length) throw new Error(`JSON missing fields: ${missing.join(', ')}`);
  return obj;
}

/** Primary provider: OpenRouter. Falls back to Gemini (if configured) so a live demo never dead-ends. */
async function generateJson(opts) {
  const errors = [];
  if (config.openrouterKey) {
    for (const model of config.openrouterModels) {
      try {
        return await openRouterJson(model, opts);
      } catch (e) {
        errors.push(`${model}: ${e.message}`);
        console.warn(`[ai] openrouter ${model} failed: ${e.message}`);
      }
    }
  }
  if (config.geminiKey) {
    try {
      return await geminiJson(opts);
    } catch (e) {
      errors.push(e.message);
    }
  }
  if (!errors.length) throw new Error('No AI provider configured (OPENROUTER_API_KEY or GEMINI_API_KEY)');
  throw new Error(`AI request failed: ${errors.join(' | ')}`);
}

async function openRouterJson(model, { system, prompt, schema, temperature = 0.4, timeoutMs }) {
  const jsonSchema = toJsonSchema(schema);
  // Spell the schema out in the prompt too: free/open models don't always enforce response_format.
  const systemWithSchema =
    `${system}\n\nRespond with ONLY a single JSON object (no markdown, no prose) matching this JSON Schema:\n` +
    JSON.stringify(jsonSchema);
  const res = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${config.openrouterKey}`,
      'X-Title': 'ScopeGuard',
    },
    body: JSON.stringify({
      model,
      temperature,
      max_tokens: config.openrouterMaxTokens,
      messages: [
        { role: 'system', content: systemWithSchema },
        { role: 'user', content: prompt },
      ],
      response_format: { type: 'json_schema', json_schema: { name: 'result', strict: true, schema: jsonSchema } },
    }),
    signal: AbortSignal.timeout(timeoutMs || Number(process.env.OPENROUTER_TIMEOUT_MS || 60_000)),
  });
  const data = await res.json();
  if (!res.ok || data.error) throw new Error(data?.error?.message || `OpenRouter HTTP ${res.status}`);
  const text = data.choices?.[0]?.message?.content || '';
  return assertShape(parseJson(text), jsonSchema);
}

async function geminiJson({ system, prompt, schema, temperature = 0.4 }) {
  const models = [config.geminiModel, ...FALLBACK_MODELS.filter((m) => m !== config.geminiModel)];
  let lastErr;
  for (const model of models) {
    try {
      const res = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        {
          method: 'POST',
          headers: { 'content-type': 'application/json', 'x-goog-api-key': config.geminiKey },
          body: JSON.stringify({
            systemInstruction: { parts: [{ text: system }] },
            contents: [{ role: 'user', parts: [{ text: prompt }] }],
            generationConfig: { temperature, responseMimeType: 'application/json', responseSchema: schema },
          }),
          signal: AbortSignal.timeout(25_000),
        },
      );
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error?.message || `Gemini HTTP ${res.status}`);
      const text = data.candidates?.[0]?.content?.parts?.map((p) => p.text || '').join('') || '';
      return parseJson(text);
    } catch (e) {
      lastErr = e;
      console.warn(`[ai] gemini ${model} failed: ${e.message}`);
    }
  }
  throw new Error(`AI request failed: ${lastErr?.message}`);
}

const SCOPER =
  'You are the senior solutions architect at a software agency that sells fixed-scope builds. ' +
  'You scope client ideas precisely, price them realistically for a small agency in USD, and split work into independent modules.';


/** Shared prompt context: overall project brief + already-priced menu items + the custom request. */
function projectContext(idea, { custom = '', menuItems = [] } = {}) {
  let out = `Project brief from the client:\n"""${idea}"""\n`;
  if (menuItems.length) {
    out +=
      '\nThe client ALREADY added these fixed-price menu items (they are priced and in scope; do NOT ask about them, ' +
      'do NOT create modules that duplicate them):\n' +
      menuItems.map((m) => `- ${m.name}: ${m.description}`).join('\n') +
      '\n';
  }
  if (custom) out += `\nCustom work the client wants on top (this is what you must scope and price):\n"""${custom}"""\n`;
  return out;
}

export async function generateQuestions(idea, extra = {}) {
  const out = await generateJson({
    system: SCOPER,
    prompt:
      projectContext(idea, extra) +
      '\nAsk 3 or 4 short, high-signal clarifying questions about the custom work that most change its scope or price ' +
      '(platforms, integrations, data/volume, must-have vs nice-to-have). Each question gets 2-4 suggested quick answers. ' +
      'Also give a short project title (max 6 words).',
    schema: {
      type: 'OBJECT',
      properties: {
        title: { type: 'STRING' },
        questions: {
          type: 'ARRAY',
          items: {
            type: 'OBJECT',
            properties: {
              question: { type: 'STRING' },
              suggestions: { type: 'ARRAY', items: { type: 'STRING' } },
            },
            required: ['question', 'suggestions'],
          },
        },
      },
      required: ['title', 'questions'],
    },
  });
  out.questions = (out.questions || []).slice(0, 4);
  return out;
}

export async function generateQuote(idea, qa, extra = {}) {
  const transcript = qa.map((x, i) => `Q${i + 1}: ${x.question}\nA${i + 1}: ${x.answer}`).join('\n');
  const out = await generateJson({
    system: SCOPER,
    prompt:
      projectContext(idea, extra) +
      `\nClarifications:\n${transcript}\n\n` +
      'Produce (1) a structured brief for the WHOLE project (list the menu items in in_scope too) with explicit in-scope ' +
      'deliverables and explicit out-of-scope items, and ' +
      '(2) 2 to 6 priced modules covering ONLY the custom work, never duplicating the menu items. Mark the core modules optional=false and nice-to-haves optional=true. ' +
      'Prices in whole US dollars between 100 and 3000 each. Keep descriptions to one sentence.',
    schema: {
      type: 'OBJECT',
      properties: {
        title: { type: 'STRING' },
        summary: { type: 'STRING' },
        target_users: { type: 'STRING' },
        platforms: { type: 'ARRAY', items: { type: 'STRING' } },
        in_scope: { type: 'ARRAY', items: { type: 'STRING' } },
        out_of_scope: { type: 'ARRAY', items: { type: 'STRING' } },
        assumptions: { type: 'ARRAY', items: { type: 'STRING' } },
        timeline_days: { type: 'INTEGER' },
        modules: {
          type: 'ARRAY',
          items: {
            type: 'OBJECT',
            properties: {
              name: { type: 'STRING' },
              description: { type: 'STRING' },
              price_usd: { type: 'INTEGER' },
              optional: { type: 'BOOLEAN' },
            },
            required: ['name', 'description', 'price_usd', 'optional'],
          },
        },
      },
      required: ['title', 'summary', 'in_scope', 'out_of_scope', 'modules', 'timeline_days'],
    },
  });
  const { modules = [], ...brief } = out;
  return {
    brief,
    modules: modules.map((m, i) => ({
      id: `m${i + 1}`,
      name: m.name,
      description: m.description,
      price_cents: Math.max(0, Math.round(Number(m.price_usd) || 0)) * 100,
      optional: !!m.optional,
      included: true,
    })),
  };
}

/**
 * Compile the paid scope into an executable contract: 2-4 acceptance criteria per module that can be
 * checked by reading source code (not by trusting anyone's word).
 */
export async function compileCriteria({ brief, modules }) {
  const out = await generateJson({
    temperature: 0.2,
    system:
      'You are a QA lead turning a fixed-price software contract into acceptance criteria. ' +
      'Each criterion must be concrete and verifiable by reading the source code of the project ' +
      '(e.g. "Password reset sends an email containing a single-use token" — not "Auth works well"). ' +
      'Avoid criteria that need a running server, design taste, or performance measurement. ' +
      'Criteria describe WHAT the software must do, never HOW: do not require a specific library, algorithm, ' +
      'token format or vendor unless the module description names it (a managed service like Supabase, Auth0, ' +
      'Clerk or Firebase satisfies an auth criterion). Only cover what the module description actually promises: ' +
      'never invent extra requirements such as icons, minimum counts, specific fields or edge cases it does not mention. ' +
      'Phrase each criterion as a user-visible or data-level behaviour ("A visitor can sign up with email and password"), ' +
      'never as an endpoint, route, function name or file.',
    prompt:
      `Project brief:\n${JSON.stringify({ title: brief?.title, summary: brief?.summary, in_scope: brief?.in_scope }, null, 2)}\n\n` +
      `Paid modules:\n${JSON.stringify(modules.map((m) => ({ module_id: m.id, name: m.name, description: m.description })), null, 2)}\n\n` +
      'For EVERY module above return 2 to 4 acceptance criteria (never more than 4). Use the exact module_id. ' +
      'For each criterion add "look_for": a short hint of what code would prove it (routes, functions, components, schema).',
    schema: {
      type: 'OBJECT',
      properties: {
        modules: {
          type: 'ARRAY',
          items: {
            type: 'OBJECT',
            properties: {
              module_id: { type: 'STRING' },
              criteria: {
                type: 'ARRAY',
                items: {
                  type: 'OBJECT',
                  properties: { text: { type: 'STRING' }, look_for: { type: 'STRING' } },
                  required: ['text', 'look_for'],
                },
              },
            },
            required: ['module_id', 'criteria'],
          },
        },
      },
      required: ['modules'],
    },
  });
  return out.modules || [];
}

/**
 * Audit a code snapshot against the acceptance criteria. The model must cite a file + line range for every
 * "proven" verdict; the caller re-checks those citations against the real files.
 */
export async function auditCode({ criteria, corpus, fileList }) {
  const out = await generateJson({
    temperature: 0.1,
    timeoutMs: 150_000,
    system:
      'You are an independent code auditor deciding whether a developer gets paid. Be strict and evidence-based. ' +
      'A criterion is "proven" ONLY if working code in the snapshot clearly implements it. ' +
      'README text, comments, TODOs, placeholder functions, mocked returns and empty components do NOT count. ' +
      '"partial" means real code exists but something required is missing. "missing" means no implementing code. ' +
      'Judge behaviour, not technology choices: any library, framework or managed service that delivers the behaviour counts. ' +
      'For proven/partial you MUST cite the single most convincing file path exactly as listed and its line range.',
    prompt:
      `Files in the snapshot:\n${fileList.join('\n')}\n\nSource code (each line prefixed with its line number):\n${corpus}\n\n` +
      `Acceptance criteria to judge:\n${criteria.map((c) => `[${c.id}] ${c.text} (look for: ${c.look_for || 'n/a'})`).join('\n')}\n\n` +
      'Return one result per criterion id. status is exactly one of: proven, partial, missing. ' +
      'file is the path ("" if missing); line_start/line_end are the cited lines (0 if missing). ' +
      'note is ONE plain-English sentence a non-technical client can understand. ' +
      'Also return summary: two plain-English sentences on overall delivery progress.',
    schema: {
      type: 'OBJECT',
      properties: {
        summary: { type: 'STRING' },
        results: {
          type: 'ARRAY',
          items: {
            type: 'OBJECT',
            properties: {
              id: { type: 'STRING' },
              status: { type: 'STRING' },
              file: { type: 'STRING' },
              line_start: { type: 'INTEGER' },
              line_end: { type: 'INTEGER' },
              note: { type: 'STRING' },
            },
            required: ['id', 'status', 'file', 'line_start', 'line_end', 'note'],
          },
        },
      },
      required: ['summary', 'results'],
    },
  });
  return out;
}

export async function checkScope({ brief, modules, message }) {
  return generateJson({
    temperature: 0.1,
    system:
      'You are ScopeGuard, a strict but fair scope-creep detector for a fixed-price software agency. ' +
      'Requests that clarify, report bugs in, or ask about status of already-paid deliverables are IN scope. ' +
      'Requests for new features, integrations, platforms, or substantially more work are OUT of scope.',
    prompt:
      `Locked brief:\n${JSON.stringify(brief, null, 2)}\n\nPaid modules:\n${JSON.stringify(
        modules.filter((m) => m.included).map((m) => ({ name: m.name, description: m.description })),
        null,
        2,
      )}\n\nNew client chat message:\n"""${message}"""\n\n` +
      'Decide if this message requests out-of-scope work. If it does, propose a single add-on with a realistic USD price.',
    schema: {
      type: 'OBJECT',
      properties: {
        out_of_scope: { type: 'BOOLEAN' },
        confidence: { type: 'NUMBER' },
        reason: { type: 'STRING' },
        suggested_addon_title: { type: 'STRING' },
        suggested_addon_description: { type: 'STRING' },
        suggested_price_usd: { type: 'INTEGER' },
      },
      required: ['out_of_scope', 'reason'],
    },
  });
}
