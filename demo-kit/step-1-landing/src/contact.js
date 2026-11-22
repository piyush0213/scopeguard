// Contact form: validates the request and emails it to the clinic's front desk.
import { Router } from 'express';
import nodemailer from 'nodemailer';

export const contactRouter = Router();
const mailer = nodemailer.createTransport(process.env.SMTP_URL || { jsonTransport: true });
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

contactRouter.post('/contact', async (req, res) => {
  const { name, email, phone = '', message } = req.body || {};
  if (!name?.trim() || !message?.trim()) return res.status(400).json({ error: 'Name and message are required' });
  if (!EMAIL.test(email || '')) return res.status(400).json({ error: 'Please enter a valid email' });
  await mailer.sendMail({
    from: 'website@brightsmile.dental',
    to: process.env.FRONT_DESK_EMAIL || 'frontdesk@brightsmile.dental',
    replyTo: email,
    subject: `Appointment request from ${name}`,
    text: `${message}\n\nPhone: ${phone || 'n/a'}\nEmail: ${email}`,
  });
  res.json({ ok: true });
});
