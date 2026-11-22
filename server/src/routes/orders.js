import { Router } from 'express';
import { loadOrderFor, listMessages } from '../services.js';
import { postChat } from '../chat.js';
import { gitInstructions } from './dev.js';
import { config } from '../config.js';
import { auditNow, proofScore } from '../proof.js';
import { syncOrderPayments } from '../payments.js';

export const ordersRouter = Router();

ordersRouter.get('/orders/:id', async (req, res) => {
  // An unpaid order with an open Stripe checkout: ask Stripe now and then, so a finished payment shows up for both
  // the client and the developer even when nobody came back from Stripe and no webhook arrived.
  const peek = await loadOrderFor(req.user, req.params.id);
  if (!peek.paid && ['negotiating', 'awaiting_payment'].includes(peek.status)) {
    await syncOrderPayments(peek.id, { minIntervalMs: 5000 }).catch(() => {});
  }
  const [order, messages] = await Promise.all([
    loadOrderFor(req.user, req.params.id),
    listMessages(req.params.id, req.user.role),
  ]);
  res.json({
    order,
    messages,
    git:
      req.user.role === 'dev' && order.branchName
        ? gitInstructions(order.branchName, order.repoFullName || undefined, order.repoSync?.defaultBranch)
        : undefined,
  });
});

// REST fallback for chat (Socket.IO `chat:send` is the primary path).
ordersRouter.post('/orders/:id/messages', async (req, res) => {
  const msg = await postChat(req.user, req.params.id, req.body?.content);
  res.status(201).json({ message: msg });
});

// Proof-of-Delivery: either party can ask for a fresh audit of the latest commit.
ordersRouter.post('/orders/:id/proof/audit', async (req, res) => {
  const order = await loadOrderFor(req.user, req.params.id);
  res.json(await auditNow(order));
});

// Proof Score: reputation computed from audited evidence, visible to clients and devs.
ordersRouter.get('/proof-score/:devId', async (req, res) => {
  res.json(await proofScore(req.params.devId));
});

ordersRouter.get('/system/status', (_req, res) => {
  res.json({
    ai: config.openrouterKey ? `OpenRouter · ${config.openrouterModels[0]}` : config.geminiKey ? 'Gemini' : null,
    stripe: !!config.stripeKey,
    stripeWebhook: !!config.stripeWebhookSecret,
    githubWebhook: !!config.githubWebhookSecret,
    githubRepo: config.githubRepo || null,
    publicUrl: config.publicUrl || null,
    autoAcceptHours: config.autoAcceptHours,
  });
});
