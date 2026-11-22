// BrightSmile Dental — web server: landing page, contact form, patient accounts.
import express from 'express';
import session from 'express-session';
import passport from 'passport';
import { contactRouter } from './src/contact.js';
import { authRouter, requireAuth } from './src/auth.js';
import { migrate } from './src/db.js';

const app = express();
app.set('trust proxy', 1);
app.use(express.json());
app.use(
  session({
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: false,
    cookie: { httpOnly: true, secure: process.env.NODE_ENV === 'production', sameSite: 'lax', maxAge: 7 * 24 * 3600 * 1000 },
  }),
);
app.use(passport.initialize());

// Patient dashboard is protected: no session, no page.
app.get('/dashboard.html', requireAuth, (_req, res) => res.sendFile('dashboard.html', { root: 'private' }));
app.use(express.static('public'));
app.use('/api', contactRouter);
app.use('/api/auth', authRouter);
app.get('/api/appointments', requireAuth, (req, res) => res.json({ patient: req.user.email, appointments: [] }));

await migrate();
const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`BrightSmile running on http://localhost:${port}`));
