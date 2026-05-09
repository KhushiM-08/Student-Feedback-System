// routes/feedback.js — Feedback Analysis Routes
// Reads the Excel files from uploads/ and returns calculated scores

const router = require('express').Router();
const XLSX   = require('xlsx');
const path   = require('path');
const fs     = require('fs');

const UPLOADS = path.join(__dirname, '../uploads');

// ── HELPER: get file path for a subject + form type ──────────
function getFilePath(subject, type) {
  const prefix  = subject === 'DVA' ? 'DVA_AI' : subject;
  const fileMap = {
    CO:  `${prefix}_CO.xlsx`,
    TL:  `${prefix}_TL.xlsx`,
    GAP: `${prefix}_CGA.xlsx`,
  };
  return path.join(UPLOADS, fileMap[type]);
}

// ── HELPER: read Excel → normalize → return average ──────────
function calcNorm(subject, type) {
  const scale    = type === 'CO' ? 3 : 5;
  const filePath = getFilePath(subject, type);

  if (!fs.existsSync(filePath)) return 0;

  const wb   = XLSX.readFile(filePath);
  const ws   = wb.Sheets[wb.SheetNames[0]];
  const rows = XLSX.utils.sheet_to_json(ws, { header: 1 }).slice(1);

  const scores = rows
    .map(row => {
      const nums = row.slice(4).filter(v => typeof v === 'number');
      return nums.length
        ? nums.reduce((a, b) => a + b, 0) / nums.length / scale
        : null;
    })
    .filter(v => v !== null);

  return scores.length
    ? parseFloat((scores.reduce((a, b) => a + b, 0) / scores.length).toFixed(4))
    : 0;
}

// ── HELPER: per-CO averages ───────────────────────────────────
function calcPerCO(subject) {
  const filePath = getFilePath(subject, 'CO');
  if (!fs.existsSync(filePath)) return [];

  const wb      = XLSX.readFile(filePath);
  const ws      = wb.Sheets[wb.SheetNames[0]];
  const rows    = XLSX.utils.sheet_to_json(ws, { header: 1 });
  const nCO     = rows[0].length - 4;

  return Array.from({ length: nCO }, (_, ci) => {
    const vals = rows.slice(1).map(r => r[4 + ci]).filter(v => typeof v === 'number');
    return vals.length
      ? parseFloat((vals.reduce((a, b) => a + b, 0) / vals.length / 3).toFixed(4))
      : 0;
  });
}

// ── GET /api/feedback/all ─────────────────────────────────────
// Summary for all 4 subjects
router.get('/all', (req, res) => {
  const result = {};
  for (const s of ['DVA', 'ML', 'SE', 'TOC']) {
    const co  = calcNorm(s, 'CO');
    const tl  = calcNorm(s, 'TL');
    const gap = calcNorm(s, 'GAP');
    const fin = parseFloat((tl * 0.4 + co * 0.4 + gap * 0.2).toFixed(4));
    result[s] = {
      co, tl, gap,
      final:  fin,
      level:  fin >= 0.75 ? 'High' : fin >= 0.5 ? 'Medium' : 'Low',
      per_co: calcPerCO(s),
    };
  }
  res.json(result);
});

// ── GET /api/feedback/analysis/:subject ──────────────────────
router.get('/analysis/:subject', (req, res) => {
  const s   = req.params.subject.toUpperCase();
  const co  = calcNorm(s, 'CO');
  const tl  = calcNorm(s, 'TL');
  const gap = calcNorm(s, 'GAP');
  const fin = parseFloat((tl * 0.4 + co * 0.4 + gap * 0.2).toFixed(4));
  res.json({
    subject: s,
    co, tl, gap,
    final:  fin,
    level:  fin >= 0.75 ? 'High' : fin >= 0.5 ? 'Medium' : 'Low',
    per_co: calcPerCO(s),
  });
});

// ── GET /api/feedback/responses/:subject/:type ───────────────
// Raw responses — all rows from the Excel file
router.get('/responses/:subject/:type', (req, res) => {
  const s    = req.params.subject.toUpperCase();
  const type = req.params.type.toUpperCase();
  const fp   = getFilePath(s, type);

  if (!fs.existsSync(fp))
    return res.status(404).json({ error: `File not found for ${s} ${type}` });

  const wb   = XLSX.readFile(fp);
  const ws   = wb.Sheets[wb.SheetNames[0]];
  const rows = XLSX.utils.sheet_to_json(ws, { header: 1 });

  res.json({
    subject:   s,
    form_type: type,
    scale:     type === 'CO' ? 3 : 5,
    questions: rows[0],
    data:      rows.slice(1),
  });
});

module.exports = router;
