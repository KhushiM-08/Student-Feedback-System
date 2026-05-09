// db.js — MySQL Connection Pool
// ============================================================
// SETUP INSTRUCTIONS:
// 1. Install MySQL and start the MySQL service
// 2. Open MySQL CLI or MySQL Workbench
// 3. Run: backend/database/schema.sql  to create the database
// 4. In backend/.env set DB_PASS to your MySQL root password
//    (leave blank if MySQL has no password set)
// ============================================================

const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host:               process.env.DB_HOST     || 'localhost',
  user:               process.env.DB_USER     || 'root',
  password:           process.env.DB_PASS     || '',
  database:           process.env.DB_NAME     || 'feedback_db',
  waitForConnections: true,
  connectionLimit:    10,
  queueLimit:         0,
  enableKeepAlive:    true,
  keepAliveInitialDelay: 0,
});

pool.getConnection()
  .then(conn => {
    console.log('  ✅ MySQL connected to:', process.env.DB_NAME || 'feedback_db');
    conn.release();
  })
  .catch(err => {
    console.warn('  ⚠️  MySQL not connected — app still runs with default credentials.');
    console.warn('     Fix: edit backend/.env and set DB_PASS, then run schema.sql');
    console.warn('     Error:', err.message);
  });

module.exports = pool;
