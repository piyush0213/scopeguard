import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { config } from './config.js';
import { one } from './db.js';

export class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

export function signToken(user) {
  return jwt.sign({ userId: user.id, role: user.role, name: user.name }, config.jwtSecret, { expiresIn: '7d' });
}
export function verifyToken(token) {
  return jwt.verify(token, config.jwtSecret);
}
const publicUser = (u) => ({ id: u.id, name: u.name, email: u.email, role: u.role });

export function requireAuth(req, _res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return next(new HttpError(401, 'Missing bearer token'));
  try {
    const p = verifyToken(token);
    req.user = { id: p.userId, role: p.role, name: p.name };
    next();
  } catch {
    next(new HttpError(401, 'Invalid or expired token'));
  }
}

export const requireRole = (...roles) => (req, _res, next) => {
  if (!req.user) return next(new HttpError(401, 'Not authenticated'));
  if (!roles.includes(req.user.role)) return next(new HttpError(403, `Requires role: ${roles.join(' or ')}`));
  next();
};

export const authRouter = Router();

authRouter.post('/register', async (req, res) => {
  const { name, email, password, role } = req.body || {};
  if (!name?.trim() || !email?.trim() || !password) throw new HttpError(400, 'Name, email and password are required');
  if (password.length < 6) throw new HttpError(400, 'Password must be at least 6 characters');
  if (!['client', 'dev'].includes(role)) throw new HttpError(400, 'Role must be client or dev');
  const exists = await one('SELECT id FROM sg_users WHERE email=$1', [email.trim().toLowerCase()]);
  if (exists) throw new HttpError(409, 'An account with this email already exists');
  const hash = await bcrypt.hash(password, 10);
  const user = await one(
    'INSERT INTO sg_users (name,email,password_hash,role) VALUES ($1,$2,$3,$4) RETURNING *',
    [name.trim(), email.trim().toLowerCase(), hash, role],
  );
  res.status(201).json({ token: signToken(user), user: publicUser(user) });
});

authRouter.post('/login', async (req, res) => {
  const { email, password } = req.body || {};
  const user = email && (await one('SELECT * FROM sg_users WHERE email=$1', [email.trim().toLowerCase()]));
  if (!user || !(await bcrypt.compare(password || '', user.password_hash))) {
    throw new HttpError(401, 'Invalid email or password');
  }
  res.json({ token: signToken(user), user: publicUser(user) });
});

authRouter.get('/me', requireAuth, async (req, res) => {
  const user = await one('SELECT * FROM sg_users WHERE id=$1', [req.user.id]);
  if (!user) throw new HttpError(401, 'User no longer exists');
  res.json({ user: publicUser(user) });
});
