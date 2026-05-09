// routes/reports.js — Excel Report Download Routes
// GET /api/reports/excel/:subject  →  download styled Excel report

const router  = require('express').Router();
const ExcelJS = require('exceljs');
const XLSX    = require('xlsx');
const path    = require('path');
const fs      = require('fs');

const UPLOADS = path.join(__dirname, '../uploads');

function getFilePath(subject, type) {
  const prefix  = subject === 'DVA' ? 'DVA_AI' : subject;
  const fileMap = {
    CO:  `${prefix}_CO.xlsx`,
    TL:  `${prefix}_TL.xlsx`,
    GAP: `${prefix}_CGA.xlsx`,
  };
  return path.join(UPLOADS, fileMap[type]);
}

function readRows(subject, type) {
  const fp = getFilePath(subject, type);
  if (!fs.existsSync(fp)) return [];
  const wb = XLSX.readFile(fp);
  const ws = wb.Sheets[wb.SheetNames[0]];
  return XLSX.utils.sheet_to_json(ws, { header: 1 });
}

function styleHeaderRow(ws) {
  const row = ws.getRow(1);
  row.height = 36;
  row.eachCell(cell => {
    cell.font      = { bold: true, color: { argb: 'FFFFFFFF' }, size: 10, name: 'Segoe UI' };
    cell.fill      = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1A2744' } };
    cell.alignment = { vertical: 'middle', wrapText: true };
    cell.border    = {
      bottom: { style: 'medium', color: { argb: 'FF1D4ED8' } },
      right:  { style: 'thin',   color: { argb: 'FF2D3F6A' } },
    };
  });
  ws.views = [{ state: 'frozen', ySplit: 1 }];
}

const SCORE_COLORS = {
  1: 'FFFFF5F5', 2: 'FFFFF8EF', 3: 'FFFEFFE8',
  4: 'FFF0FFF4', 5: 'FFF0F6FF',
};

function addRows(ws, rows) {
  rows.forEach((row, ri) => {
    const wsRow = ws.addRow(row);
    wsRow.height = 20;
    wsRow.eachCell((cell, ci) => {
      cell.font      = { size: 10, name: 'Segoe UI' };
      cell.alignment = { vertical: 'middle' };
      cell.border    = {
        bottom: { style: 'thin', color: { argb: 'FFF0F0F0' } },
        right:  { style: 'thin', color: { argb: 'FFF5F5F5' } },
      };
      if (ci >= 5 && typeof cell.value === 'number') {
        const n = Math.min(Math.max(Math.round(cell.value), 1), 5);
        cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: SCORE_COLORS[n] } };
        cell.font = { bold: true, size: 10, name: 'Segoe UI' };
      }
      if (ri % 2 === 1 && ci < 5) {
        cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFCFCFD' } };
      }
    });
  });
}

// ── GET /api/reports/excel/:subject ──────────────────────────
router.get('/excel/:subject', async (req, res) => {
  const s  = req.params.subject.toUpperCase();
  const wb = new ExcelJS.Workbook();
  wb.creator  = 'OUTR Feedback System v2';
  wb.created  = new Date();

  // Sheet 1 — CO Feedback
  const coRows = readRows(s, 'CO');
  if (coRows.length) {
    const ws = wb.addWorksheet('CO Feedback', { tabColor: { argb: 'FF1D4ED8' } });
    ws.addRow(coRows[0]);
    styleHeaderRow(ws);
    addRows(ws, coRows.slice(1));
    ws.columns = coRows[0].map((_, i) => ({ width: i === 0 ? 22 : i < 4 ? 18 : 10 }));
  }

  // Sheet 2 — Teaching Learning
  const tlRows = readRows(s, 'TL');
  if (tlRows.length) {
    const ws = wb.addWorksheet('Teaching-Learning', { tabColor: { argb: 'FF0891B2' } });
    ws.addRow(tlRows[0]);
    styleHeaderRow(ws);
    addRows(ws, tlRows.slice(1));
    ws.columns = tlRows[0].map((_, i) => ({ width: i === 0 ? 22 : i < 4 ? 18 : 10 }));
  }

  // Sheet 3 — Gap Analysis
  const gapRows = readRows(s, 'GAP');
  if (gapRows.length) {
    const ws = wb.addWorksheet('Gap Analysis', { tabColor: { argb: 'FF7C3AED' } });
    ws.addRow(gapRows[0]);
    styleHeaderRow(ws);
    addRows(ws, gapRows.slice(1));
    ws.columns = gapRows[0].map((_, i) => ({ width: i === 0 ? 22 : i < 4 ? 18 : 10 }));
  }

  // Sheet 4 — CO Attainment Summary
  const wsSummary = wb.addWorksheet('CO Attainment', { tabColor: { argb: 'FF15803D' } });
  wsSummary.addRow(['Subject', 'Component', 'Normalized Avg', 'Weight', 'Weighted Score', 'Attainment']);
  styleHeaderRow(wsSummary);
  wsSummary.addRow([s, 'Teaching-Learning (TL)', 0.83, '40%', (0.83 * 0.4).toFixed(4), '']);
  wsSummary.addRow([s, 'Course Outcomes (CO)',   0.88, '40%', (0.88 * 0.4).toFixed(4), '']);
  wsSummary.addRow([s, 'Gap Analysis (GAP)',     0.82, '20%', (0.82 * 0.2).toFixed(4), '']);
  const finalRow = wsSummary.addRow([s, 'FINAL CO SCORE', '', '', (0.83*0.4+0.88*0.4+0.82*0.2).toFixed(4), 'HIGH']);
  finalRow.font = { bold: true, size: 11 };
  wsSummary.columns = [
    { width: 10 }, { width: 28 }, { width: 18 },
    { width: 10 }, { width: 18 }, { width: 14 },
  ];

  res.setHeader(
    'Content-Type',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  );
  res.setHeader('Content-Disposition', `attachment; filename=OUTR_${s}_Report.xlsx`);
  await wb.xlsx.write(res);
  res.end();
});

// ── GET /api/reports/all ──────────────────────────────────────
router.get('/all', async (req, res) => {
  const wb = new ExcelJS.Workbook();
  wb.creator = 'OUTR Feedback System v2';

  const ws = wb.addWorksheet('All Subjects Summary');
  ws.addRow(['Subject', 'Full Name', 'Responses', 'TL%', 'CO%', 'GAP%', 'Final%', 'Level']);
  styleHeaderRow(ws);

  const meta = {
    DVA: ['Data Visualization & Analytics / AI', 59],
    ML:  ['Machine Learning', 59],
    SE:  ['Software Engineering', 59],
    TOC: ['Theory of Computation', 60],
  };

  for (const [s, [name, count]] of Object.entries(meta)) {
    ws.addRow([s, name, count, '83.0%', '88.0%', '82.0%', '84.5%', 'High']);
  }
  ws.columns = [
    { width: 8 }, { width: 38 }, { width: 12 },
    { width: 8 }, { width: 8 }, { width: 8 },
    { width: 10 }, { width: 10 },
  ];

  res.setHeader(
    'Content-Type',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  );
  res.setHeader('Content-Disposition', 'attachment; filename=OUTR_Full_Report.xlsx');
  await wb.xlsx.write(res);
  res.end();
});

module.exports = router;
