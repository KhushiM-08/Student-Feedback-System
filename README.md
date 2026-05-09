# OUTR Feedback System v3

Student Feedback Portal for Odisha University of Technology and Research (OUTR), Bhubaneswar.

---

## 🚀 Quick Start (localhost / VS Code)

### Step 1 — Prerequisites
- [Node.js](https://nodejs.org/) v18 or later
- [MySQL](https://dev.mysql.com/downloads/mysql/) 8.0 or later (optional but recommended)

### Step 2 — Setup MySQL Database
1. Start your MySQL server
2. Open MySQL Workbench or MySQL CLI
3. Run the SQL file to create and populate the database:
   ```sql
   source /path/to/backend/database/schema.sql
   ```
   Or in MySQL CLI:
   ```
   mysql -u root -p < backend/database/schema.sql
   ```

### Step 3 — Configure Environment
Open `backend/.env` and set your MySQL password:
```
DB_HOST=localhost
DB_USER=root
DB_PASS=your_password_here     ← change this
DB_NAME=feedback_db
JWT_SECRET=outr_feedback_secret_2025
PORT=3000
```
> **No MySQL password?** Leave `DB_PASS=` blank. The app also works without MySQL using built-in credentials.

### Step 4 — Install & Run
```bash
cd backend
npm install
node server.js
```

### Step 5 — Open in Browser
```
http://localhost:3000
```

---

## 🔑 Login Credentials

| Role            | Username / RegNo | Password     |
|-----------------|------------------|--------------|
| Student         | Any RegNo        | ≥ 75% attendance |
| Faculty / HOD / Advisor | `faculty` | `faculty123` |
| Admin           | `admin`          | `admin123`   |
| HOD             | `hod`            | `hod123`     |

> If MySQL is connected, credentials are read from the `admins` table in the database.

---

## 📁 Project Structure
```
outr-feedback-v3/
├── backend/
│   ├── server.js          ← Express server entry point
│   ├── db.js              ← MySQL connection pool
│   ├── .env               ← Environment variables (edit DB_PASS here)
│   ├── package.json
│   ├── routes/
│   │   ├── auth.js        ← Login API
│   │   ├── feedback.js    ← Feedback API
│   │   └── reports.js     ← Reports API
│   ├── database/
│   │   └── schema.sql     ← Full MySQL database schema + data
│   └── uploads/           ← Excel data files
└── frontend/
    └── index.html         ← Complete single-page frontend
```

---

## 🛠 VS Code Tips
- Install the **REST Client** extension to test APIs
- Install **MySQL** extension to browse the database
- Use `npm run dev` to auto-restart on file changes (requires nodemon)

---

## ⚠️ Troubleshooting

| Problem | Fix |
|---------|-----|
| `Cannot connect to MySQL` | Check MySQL is running; verify DB_PASS in .env |
| `Port 3000 already in use` | Change `PORT=3001` in .env |
| `Module not found` | Run `npm install` in the backend folder |
| `schema.sql error` | Drop database first: `DROP DATABASE IF EXISTS feedback_db;` |
