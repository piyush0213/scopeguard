import express from 'express';
import http from 'node:http';
import path from 'node:path';
import fs from 'node:fs';
import cors from 'cors';
import { config } from './config.js';
import { migrate } from './db.js';
import { seed } from './seed.js';
import { authRouter, requireAuth, HttpError } from './auth.js';
import { initRealtime } from './realtime.js';
import { canJoin, postChat } from './chat.js';
import { clientRouter } from './routes/client.js';
import { devRouter } from './routes/dev.js';
import { ordersRouter } from './routes/orders.js';
import { webhookRouter } from './routes/webhooks.js';
import { startGithubSync } from './github-sync.js';

const app = express();
const server = http.createServer(app);
const origins = [config.appUrl, 'http://localhost:5173', 'http://127.0.0.1:5173'];

app.set('trust proxy', 1);
app.use(cors({ origin: origins, credentials: true }));

// Webhooks need the raw body for signature checks, so mount before express.json().
app.use(webhookRouter);
app.use(express.json({ limit: '1mb' }));

app.get('/health', (_req, res) => res.json({ ok: true }));
app.use('/api/auth', authRouter);
app.use('/api', requireAuth, clientRouter, devRouter, ordersRouter);

// Serve the built client in production (single-origin deploy, e.g. Render).
const dist = path.resolve(import.meta.dirname, '../../client/dist');
if (fs.existsSync(dist)) {
  app.use(express.static(dist));
  app.get(/^\/(?!api|webhooks|demo|socket\.io).*/, (_req, res) => res.sendFile(path.join(dist, 'index.html')));
}

app.use((err, _req, res, _next) => {
  const status = err instanceof HttpError ? err.status : err.type === 'entity.parse.failed' ? 400 : 500;
  if (status >= 500) console.error('[error]', err);
  res.status(status).json({ error: status >= 500 && !(err instanceof HttpError) ? err.message || 'Server error' : err.message });
});

initRealtime(server, origins, { canJoin, onChat: postChat });

await migrate();
await seed();
server.listen(config.port, async () => {
  console.log(`ScopeGuard API on http://localhost:${config.port}`);
  console.log(
    `  ai=${config.openrouterKey ? "openrouter:" + config.openrouterModels[0] : config.geminiKey ? "gemini" : "none"} stripe=${!!config.stripeKey} stripeWebhook=${!!config.stripeWebhookSecret} githubWebhook=${!!config.githubWebhookSecret}`,
  );
  await startGithubSync();
});
