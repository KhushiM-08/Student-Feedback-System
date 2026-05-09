// routes/auth.js — Login Routes
// POST /api/auth/student  →  attendance check, returns JWT
// POST /api/auth/admin    →  username/password check, returns JWT

const router = require('express').Router();
const jwt    = require('jsonwebtoken');

let db;
try { db = require('../db'); } catch (e) { db = null; }

const SECRET = process.env.JWT_SECRET || 'outr_secret_2025';

// Default credentials (used when MySQL is not connected)
const DEFAULT_USERS = {
  admin:   { password: 'admin123',   role: 'admin'   },
  faculty: { password: 'faculty123', role: 'faculty' },
  hod:     { password: 'hod123',     role: 'hod'     },
};

// ── POST /api/auth/student ────────────────────────────────────
// Body: { reg_no, attendance }
router.post('/student', async (req, res) => {
  const { reg_no, attendance } = req.body;

  if (!reg_no)
    return res.status(400).json({ error: 'Registration number is required.' });

  const att = parseFloat(attendance);
  if (isNaN(att))
    return res.status(400).json({ error: 'Attendance must be a number.' });

  if (att < 75)
    return res.status(403).json({
      error: `Access Denied — Attendance ${att}% is below the 75% minimum.`
    });

  // Save to DB if available
  if (db) {
    try {
      await db.execute(
        `INSERT INTO students (reg_no, attendance)
         VALUES (?, ?)
         ON DUPLICATE KEY UPDATE attendance = ?`,
        [reg_no, att, att]
      );
    } catch (e) { /* DB not ready, skip */ }
  }

  const token = jwt.sign({ reg_no, role: 'student' }, SECRET, { expiresIn: '2h' });
  res.json({ success: true, token, reg_no });
});

// ── POST /api/auth/admin ──────────────────────────────────────
// Body: { username, password }
router.post('/admin', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password)
    return res.status(400).json({ error: 'Username and password are required.' });

  // Try DB first
  if (db) {
    try {
      const [rows] = await db.execute(
        'SELECT * FROM admins WHERE username = ?', [username]
      );
      if (rows.length && rows[0].password_hash === password) {
        const token = jwt.sign({ username, role: rows[0].role }, SECRET, { expiresIn: '8h' });
        return res.json({ success: true, token, role: rows[0].role });
      }
      if (rows.length)
        return res.status(401).json({ error: 'Invalid password.' });
    } catch (e) { /* fallback to defaults */ }
  }

  // Fallback: default credentials
  const user = DEFAULT_USERS[username];
  if (!user || user.password !== password)
    return res.status(401).json({ error: 'Invalid username or password.' });

  const token = jwt.sign({ username, role: user.role }, SECRET, { expiresIn: '8h' });
  res.json({ success: true, token, role: user.role });
});

module.exports = router;
