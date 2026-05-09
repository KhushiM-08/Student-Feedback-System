// ============================================================
// server.js — OUTR Feedback System v3
// ============================================================
// HOW TO RUN:
//   1. cd backend
//   2. npm install
//   3. node server.js
//   4. Open browser: http://localhost:3000
// ============================================================

const express = require('express');
const cors    = require('cors');
const path    = require('path');
require('dotenv').config();

const app = express();

// ── MIDDLEWARE ────────────────────────────────────────────────
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve the frontend folder as static files
// index.html is served at http://localhost:3000
app.use(express.static(path.join(__dirname, '../frontend')));

// ── API ROUTES ────────────────────────────────────────────────
app.use('/api/auth',     require('./routes/auth'));
app.use('/api/feedback', require('./routes/feedback'));
app.use('/api/reports',  require('./routes/reports'));

// ── HEALTH CHECK ─────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({
    status:    'running',
    project:   'OUTR Feedback System v3',
    version:   '2.0.0',
    timestamp: new Date().toISOString(),
  });
});

// ── CATCH-ALL: serve index.html for any unknown route ────────
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '../frontend', 'index.html'));
});

// ── START SERVER ─────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log('');
  console.log('╔══════════════════════════════════════════════════╗');
  console.log('║     OUTR Feedback System v3 — Running    ║');
  console.log('╠══════════════════════════════════════════════════╣');
  console.log(`║  Open this in Chrome: http://localhost:${PORT}       ║`);
  console.log('╚══════════════════════════════════════════════════╝');
  console.log('');
  console.log('  Student  →  any reg no  +  attendance >= 75%');
  console.log('  Faculty  →  username: faculty   password: faculty123');
  console.log('  HOD      →  username: hod       password: hod123');
  console.log('  Admin    →  username: admin     password: admin123');
  console.log('');
  console.log('  Press Ctrl+C to stop.');
  console.log('');
});
