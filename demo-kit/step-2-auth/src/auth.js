// Patient accounts: email/password + Google sign-in, password reset by email, sessions, protected routes.
import crypto from 'node:crypto';
import { Router } from 'express';
import bcrypt from 'bcryptjs';
import passport from 'passport';
import { Strategy as GoogleStrategy } from 'passport-google-oauth20';
import nodemailer from 'nodemailer';
import { db } from './db.js';

export const authRouter = Router();
const mailer = nodemailer.createTransport(process.env.SMTP_URL || { jsonTransport: true });
const RESET_TTL_MS = 30 * 60 * 1000;

/* ---------------- sessions ---------------- */
function startSession(req, user) {
  return new Promise((resolve, reject) =>
    req.session.regenerate((err) => {
      if (err) return reject(err);
      req.session.userId = user.id;
      resolve();
    }),
  );
}

/** Protected routes: reject any request without a valid session. */
export async function requireAuth(req, res, next) {
  const user = req.session?.userId && (await db.one('SELECT id, email, name FROM users WHERE id=$1', [req.session.userId]));
  if (!user) return res.status(401).json({ error: 'Please sign in' });
  req.user = user;
  next();
}

/* ---------------- email + password ---------------- */
authRouter.post('/register', async (req, res) => {
  const { email, password, name } = req.body || {};
  if (!email || !password || password.length < 8) return res.status(400).json({ error: 'Email and a password of 8+ characters are required' });
  if (await db.one('SELECT 1 FROM users WHERE email=$1', [email.toLowerCase()])) return res.status(409).json({ error: 'Email already registered' });
  const hash = await bcrypt.hash(password, 12);
  const verifyToken = crypto.randomBytes(32).toString('hex');
  const user = await db.one(
    'INSERT INTO users (email, name, password_hash, verify_token_hash) VALUES ($1,$2,$3,$4) RETURNING id, email, name',
    [email.toLowerCase(), name || '', hash, crypto.createHash('sha256').update(verifyToken).digest('hex')],
  );
  await mailer.sendMail({
    from: 'no-reply@brightsmile.dental',
    to: user.email,
    subject: 'Confirm your BrightSmile account',
    text: `Welcome! Confirm your email: ${process.env.APP_URL}/api/auth/verify-email?token=${verifyToken}`,
  });
  await startSession(req, user);
  res.status(201).json({ user });
});

authRouter.get('/verify-email', async (req, res) => {
  const tokenHash = crypto.createHash('sha256').update(String(req.query.token || '')).digest('hex');
  const user = await db.one('UPDATE users SET email_verified=true, verify_token_hash=NULL WHERE verify_token_hash=$1 RETURNING id', [tokenHash]);
  res.redirect(user ? '/dashboard.html?verified=1' : '/login.html?error=verify');
});

authRouter.post('/login', async (req, res) => {
  const { email, password } = req.body || {};
  const row = await db.one('SELECT * FROM users WHERE email=$1', [String(email || '').toLowerCase()]);
  if (!row?.password_hash || !(await bcrypt.compare(String(password || ''), row.password_hash))) {
    return res.status(401).json({ error: 'Wrong email or password' });
  }
  await startSession(req, row);
  res.json({ user: { id: row.id, email: row.email, name: row.name } });
});

authRouter.post('/logout', (req, res) => req.session.destroy(() => res.json({ ok: true })));

authRouter.get('/me', requireAuth, (req, res) => res.json({ user: req.user }));

/* ---------------- password reset ---------------- */
authRouter.post('/forgot-password', async (req, res) => {
  const user = await db.one('SELECT id, email FROM users WHERE email=$1', [String(req.body?.email || '').toLowerCase()]);
  if (user) {
    const token = crypto.randomBytes(32).toString('hex');
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
    await db.query('UPDATE users SET reset_token_hash=$2, reset_expires=$3 WHERE id=$1', [user.id, tokenHash, new Date(Date.now() + RESET_TTL_MS)]);
    await mailer.sendMail({
      from: 'no-reply@brightsmile.dental',
      to: user.email,
      subject: 'Reset your BrightSmile password',
      text: `Reset your password (valid 30 minutes): ${process.env.APP_URL}/reset.html?token=${token}`,
    });
  }
  res.json({ ok: true }); // same answer either way, so emails can't be enumerated
});

authRouter.post('/reset-password', async (req, res) => {
  const { token, password } = req.body || {};
  if (!token || !password || password.length < 8) return res.status(400).json({ error: 'Token and a new 8+ character password are required' });
  const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
  const user = await db.one('SELECT id FROM users WHERE reset_token_hash=$1 AND reset_expires > now()', [tokenHash]);
  if (!user) return res.status(400).json({ error: 'Reset link is invalid or expired' });
  await db.query('UPDATE users SET password_hash=$2, reset_token_hash=NULL, reset_expires=NULL WHERE id=$1', [user.id, await bcrypt.hash(password, 12)]);
  res.json({ ok: true });
});

/* ---------------- Google sign-in ---------------- */
passport.use(
  new GoogleStrategy(
    { clientID: process.env.GOOGLE_CLIENT_ID, clientSecret: process.env.GOOGLE_CLIENT_SECRET, callbackURL: '/api/auth/google/callback' },
    async (_access, _refresh, profile, done) => {
      try {
        const email = profile.emails?.[0]?.value?.toLowerCase();
        const user =
          (await db.one('SELECT id, email, name FROM users WHERE google_id=$1', [profile.id])) ||
          (await db.one(
            `INSERT INTO users (email, name, google_id) VALUES ($1,$2,$3)
             ON CONFLICT (email) DO UPDATE SET google_id=EXCLUDED.google_id RETURNING id, email, name`,
            [email, profile.displayName, profile.id],
          ));
        done(null, user);
      } catch (e) {
        done(e);
      }
    },
  ),
);

authRouter.get('/google', passport.authenticate('google', { scope: ['profile', 'email'], session: false }));
authRouter.get('/google/callback', passport.authenticate('google', { session: false, failureRedirect: '/login.html?error=google' }), async (req, res) => {
  await startSession(req, req.user);
  res.redirect('/dashboard.html');
});
