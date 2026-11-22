import bcrypt from 'bcryptjs';
import { query } from './db.js';

const MENU = [
  ['landing-page', 'Landing Page', 'Responsive marketing page with hero, features, pricing and contact form. Deployed on Vercel.', 30000, 3, '🖥️'],
  ['auth-module', 'Auth Module', 'Email/password + Google sign-in, password reset, protected routes and session handling.', 25000, 2, '🔐'],
  ['stripe-payments', 'Stripe Payments', 'Checkout, subscriptions or one-time payments with webhooks and receipt emails.', 40000, 3, '💳'],
  ['admin-dashboard', 'Admin Dashboard', 'CRUD tables, search, filters and charts over your data with role-based access.', 60000, 5, '📊'],
];

export const DEMO_PASSWORD = 'demo1234';
const DEMO_USERS = [
  ['Asha (Clinic Owner)', 'client@demo.dev', 'client'],
  ['Ravi (Agency Dev)', 'dev@demo.dev', 'dev'],
];

export async function seed() {
  for (const [id, name, description, price, eta, emoji] of MENU) {
    await query(
      `INSERT INTO sg_menu_items (id,name,description,price_cents,eta_days,emoji)
       VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT (id) DO NOTHING`,
      [id, name, description, price, eta, emoji],
    );
  }
  const hash = await bcrypt.hash(DEMO_PASSWORD, 10);
  for (const [name, email, role] of DEMO_USERS) {
    await query(
      `INSERT INTO sg_users (name,email,password_hash,role) VALUES ($1,$2,$3,$4)
       ON CONFLICT (email) DO NOTHING`,
      [name, email, hash, role],
    );
  }
}
