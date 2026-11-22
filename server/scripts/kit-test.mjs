// Dry-run the auditor on the local demo kit (no GitHub, no push): node scripts/kit-test.mjs
import fs from 'node:fs';
import path from 'node:path';
import { compileCriteria, auditCode } from '../src/ai.js';

const kit = path.resolve(import.meta.dirname, '../../demo-kit');
const modules = [
  { id: 'menu-auth-module', name: 'Auth Module', description: 'Email/password + Google sign-in, password reset, protected routes and session handling.' },
  { id: 'menu-landing-page', name: 'Landing Page', description: 'Responsive marketing page with hero, features, pricing and contact form. Deployed on Vercel.' },
];
const walk = (dir, base = dir) =>
  fs.readdirSync(dir, { withFileTypes: true }).flatMap((e) => {
    const p = path.join(dir, e.name);
    return e.isDirectory() ? walk(p, base) : [[path.relative(base, p).replaceAll('\\', '/'), fs.readFileSync(p, 'utf8')]];
  });

const compiled = await compileCriteria({ brief: { title: 'Dental clinic site', summary: 'Clinic website with patient accounts' }, modules });
const criteria = compiled.flatMap((m) => m.criteria.map((c, i) => ({ id: `${m.module_id}.c${i + 1}`, ...c })));

for (const step of [1, 2]) {
  const files = new Map(walk(path.join(kit, 'step-1-landing')));
  if (step === 2) for (const [p, t] of walk(path.join(kit, 'step-2-auth'))) files.set(p, t);
  const corpus = [...files].map(([p, t]) => `=== ${p} ===\n${t.split('\n').map((l, i) => `${i + 1}| ${l}`).join('\n')}`).join('\n\n');
  const out = await auditCode({ criteria, corpus, fileList: [...files.keys()] });
  console.log(`\n=== STEP ${step} ===`);
  for (const m of modules) {
    const rs = criteria.filter((c) => c.id.startsWith(m.id)).map((c) => [c, out.results.find((r) => r.id === c.id) || {}]);
    console.log(`${m.name}: ${rs.every(([, r]) => r.status === 'proven') ? 'RELEASE' : 'HELD'}`);
    for (const [c, r] of rs) console.log(`   ${String(r.status).padEnd(7)} ${c.text}  [${r.file}:${r.line_start}]`);
  }
}
