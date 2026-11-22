// BrightSmile Dental — web server. Serves the landing page and handles the contact form.
import express from 'express';
import { contactRouter } from './src/contact.js';

const app = express();
app.use(express.json());
app.use(express.static('public'));
app.use('/api', contactRouter);

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`BrightSmile running on http://localhost:${port}`));
