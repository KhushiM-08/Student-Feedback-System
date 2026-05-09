-- ============================================================
-- OUTR Student Feedback System — Complete MySQL Database
-- HOW TO RUN:
--   mysql -u root -p < database/schema.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS feedback_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE feedback_db;

-- Drop tables in reverse FK order
DROP TABLE IF EXISTS co_attainment;
DROP TABLE IF EXISTS feedback_raw;
DROP TABLE IF EXISTS co_mapping;
DROP TABLE IF EXISTS admins;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS subjects;

-- ==================== TABLE: students ====================
CREATE TABLE students (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  reg_no      VARCHAR(25) UNIQUE NOT NULL,
  name        VARCHAR(120),
  attendance  FLOAT DEFAULT 0,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== TABLE: subjects ====================
CREATE TABLE subjects (
  id       INT AUTO_INCREMENT PRIMARY KEY,
  code     VARCHAR(10) UNIQUE NOT NULL,
  name     VARCHAR(120) NOT NULL,
  semester INT DEFAULT 5
);

INSERT INTO subjects (code, name, semester) VALUES
  ('DVA', 'Data Visualization & Analytics / AI', 5),
  ('ML',  'Machine Learning', 5),
  ('TOC', 'Theory of Computation', 5),
  ('SE',  'Software Engineering', 5);

-- ==================== TABLE: admins ====================
CREATE TABLE admins (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  username      VARCHAR(50) UNIQUE,
  password_hash VARCHAR(255),
  role          ENUM('admin','faculty','hod') DEFAULT 'faculty',
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Passwords: admin=admin123  faculty=faculty123  hod=hod123
-- (plain text stored here for dev; use bcrypt in production)
INSERT INTO admins (username, password_hash, role) VALUES
  ('admin',   'admin123',   'admin'),
  ('faculty', 'faculty123', 'faculty'),
  ('hod',     'hod123',     'hod');

-- ==================== TABLE: co_mapping ====================
CREATE TABLE co_mapping (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  subject_code   VARCHAR(10),
  co_number      INT,
  co_description TEXT,
  po1_weight     INT DEFAULT 0,
  po2_weight     INT DEFAULT 0,
  po3_weight     INT DEFAULT 0,
  FOREIGN KEY (subject_code) REFERENCES subjects(code)
);

INSERT INTO co_mapping (subject_code, co_number, co_description, po1_weight, po2_weight, po3_weight) VALUES
  ('DVA', 1, 'Understand data analytics concepts and their applications in AI', 3, 0, 0),
  ('DVA', 2, 'Perform data cleaning, transformation, and exploratory data analysis (EDA)', 2, 3, 0),
  ('DVA', 3, 'Visualize different types of data using appropriate graphical tools', 0, 2, 3),
  ('DVA', 4, 'Create dashboards and interpret real-world datasets', 0, 0, 2),
  ('ML',  1, 'Understand the need for machine learning for various problem solving', 3, 0, 0),
  ('ML',  2, 'Understand various algorithms and evaluate models', 2, 3, 0),
  ('ML',  3, 'Apply machine learning features on real world problems', 0, 2, 3),
  ('ML',  4, 'Design and analyse artificial neural networks and deep learning models', 0, 0, 2),
  ('TOC', 1, 'Understand Formal Languages, Grammar and Computational Models', 3, 0, 0),
  ('TOC', 2, 'Analyze and Design Finite Automata', 2, 3, 0),
  ('TOC', 3, 'Evaluate Pushdown Automata and Context-Free Languages', 0, 2, 3),
  ('TOC', 4, 'Understand Turing Machines and Computability', 0, 0, 2),
  ('SE',  1, 'Understand software engineering fundamentals and lifecycle models', 3, 0, 0),
  ('SE',  2, 'Apply software size metrics and estimation techniques', 2, 3, 0),
  ('SE',  3, 'Demonstrate structured and object-oriented design principles', 0, 2, 3),
  ('SE',  4, 'Analyze software testing strategies and maintenance practices', 0, 0, 2);

-- ==================== TABLE: feedback_raw ====================
CREATE TABLE feedback_raw (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  reg_no       VARCHAR(25),
  subject_code VARCHAR(10),
  form_type    ENUM('CO','TL','GAP'),
  q1  FLOAT, q2  FLOAT, q3  FLOAT, q4  FLOAT,
  q5  FLOAT, q6  FLOAT, q7  FLOAT, q8  FLOAT,
  q9  FLOAT, q10 FLOAT, q11 FLOAT, q12 FLOAT,
  avg_score    FLOAT,
  norm_score   FLOAT,
  submitted_at VARCHAR(30),
  FOREIGN KEY (subject_code) REFERENCES subjects(code)
);

-- ==================== TABLE: co_attainment ====================
CREATE TABLE co_attainment (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  subject_code     VARCHAR(10),
  co_number        INT,
  co_label         VARCHAR(20),
  normalized_score FLOAT,
  attainment_level ENUM('High','Medium','Low'),
  FOREIGN KEY (subject_code) REFERENCES subjects(code)
);

-- ==================== VIEWS ====================
CREATE OR REPLACE VIEW v_subject_summary AS
SELECT
  subject_code,
  form_type,
  COUNT(*)                   AS responses,
  ROUND(AVG(norm_score), 4)  AS avg_normalized
FROM feedback_raw
GROUP BY subject_code, form_type;

CREATE OR REPLACE VIEW v_final_co_score AS
SELECT
  subject_code,
  ROUND(
    SUM(CASE WHEN form_type='TL'  THEN avg_normalized * 0.4 ELSE 0 END) +
    SUM(CASE WHEN form_type='CO'  THEN avg_normalized * 0.4 ELSE 0 END) +
    SUM(CASE WHEN form_type='GAP' THEN avg_normalized * 0.2 ELSE 0 END)
  , 4) AS final_score,
  CASE
    WHEN SUM(CASE WHEN form_type='TL'  THEN avg_normalized*0.4 ELSE 0 END)+
         SUM(CASE WHEN form_type='CO'  THEN avg_normalized*0.4 ELSE 0 END)+
         SUM(CASE WHEN form_type='GAP' THEN avg_normalized*0.2 ELSE 0 END) >= 0.75 THEN 'High'
    WHEN SUM(CASE WHEN form_type='TL'  THEN avg_normalized*0.4 ELSE 0 END)+
         SUM(CASE WHEN form_type='CO'  THEN avg_normalized*0.4 ELSE 0 END)+
         SUM(CASE WHEN form_type='GAP' THEN avg_normalized*0.2 ELSE 0 END) >= 0.50 THEN 'Medium'
    ELSE 'Low'
  END AS attainment_level
FROM v_subject_summary
GROUP BY subject_code;

-- ==================== STUDENT DATA ====================

-- Students (60 unique)
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('2211100196', 'Bhadreswar Mundary', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110250', 'Abhinandan Sahu', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110256', 'Adyasha Das', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110258', 'Aliva Bhuyan', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110259', 'Ansu Ranit Kerketta', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110261', 'Asit sahoo', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110262', 'Ayush kumar Barik', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110264', 'Debasis panda', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110266', 'Dibyadisha sahoo', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110268', 'Dinesh Chandra Mohanty', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110269', 'Divyajyoti Ghadai', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110270', 'Gouri Baskey', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110272', 'Hemant xalxo', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110273', 'Ipsita Mahapatro', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110275', 'K OM SENAPATI', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110276', 'Karanam Prasant', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110277', 'Ketan Mohanty', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110279', 'Khushi Mandal', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110280', 'Kritika Tandy', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110281', 'Lipsita Mahapatro', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110282', 'MANASI MAHARANA', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110284', 'Mousumi Naik', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110285', 'Om satyam dey', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110287', 'Ommkar Pattnaik', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110289', 'Prabhupratik Pattanaik', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110290', 'PRASANTA MOHANTY', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110291', 'Prateek Mishra', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110292', 'PRATIKSHYA PRIYADARSHINI', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110293', 'Priyadarshini Sahani', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110295', 'Pruthwiraj Sanibigraha', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110296', 'R. H. Arijit', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110297', 'Rakesh Sahu', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110298', 'Sahil Tripathy', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110299', 'Saloni Mohapatra', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110300', 'Samikhya panigrahi', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110302', 'Santosh Samal', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110303', 'Sasank Sekhar Bisoyi', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110305', 'Satyajit Das', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110311', 'Simran Palai', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110312', 'Somen Subhadip Rout', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110313', 'Soumya Safallya Sahoo', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110315', 'Sovan Kumar Mohapatra', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110318', 'Subhasis Rout', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110320', 'SUJALL MOHAPATRA', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110321', 'Suman Subhra Chandan Sethy', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110322', 'Surya Narayan Dash', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110325', 'Upendra Murmu', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110327', 'VIVEKANANDA GURU', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110395', 'Adarsh Swain', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110462', 'PARITOSH RATH', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110581', 'Prayas Kumar Nayak', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110701', 'Swayam Subhankar Sahoo', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('23110791', 'Priyanka Swain', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('24120021', 'Abhijit Mohanty', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('24120025', 'G Khetrabasi Reddy', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('24120027', 'Mir Enayatulla Quadri', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('24120028', 'Purna Chandra Jena', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('24120029', 'sandeep ekka', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('24120030', 'Subhashree Das', 80.0);
INSERT IGNORE INTO students (reg_no, name, attendance) VALUES ('24120031', 'Sumeet Hota', 80.0);

-- Feedback Raw Responses

-- DVA (59 students)
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('2211100196','DVA','CO',2, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/14/2026 10:28:32');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('2211100196','DVA','TL',5, 5, 4, 3, 3, 4, 5, 5, 3, 5, 4, 5,4.25,0.85,'4/14/2026 10:28:32');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('2211100196','DVA','GAP',3, 5, 5, 1, 1, 5, 5, 4, 4, 2, 4, 5,3.6667,0.7333,'4/14/2026 10:28:32');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110250','DVA','CO',2, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/12/2026 11:47:38');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110250','DVA','TL',4, 5, 5, 4, 1, 5, 5, 5, 5, 5, 5, 4,4.4167,0.8833,'4/12/2026 11:47:38');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110250','DVA','GAP',3, 5, 5, 5, 5, 5, 5, 5, 5, 3, 5, 5,4.6667,0.9333,'4/12/2026 11:47:38');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110256','DVA','CO',3, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/14/2026 18:30:50');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110256','DVA','TL',3, 5, 5, 5, 2, 4, 5, 3, 5, 5, 5, 4,4.25,0.85,'4/14/2026 18:30:50');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110256','DVA','GAP',4, 5, 4, 5, 5, 2, 2, 5, 5, 3, 5, 5,4.1667,0.8333,'4/14/2026 18:30:50');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110258','DVA','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/15/2026 12:45:45');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110258','DVA','TL',3, 5, 4, 5, 5, 5, 5, 5, 4, 2, 4, 4,4.25,0.85,'4/15/2026 12:45:45');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110258','DVA','GAP',4, 5, 3, 4, 3, 5, 5, 5, 3, 4, 4, 5,4.1667,0.8333,'4/15/2026 12:45:45');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110259','DVA','CO',3, 1, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/18/2026 11:18:57');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110259','DVA','TL',5, 5, 5, 4, 5, 5, 5, 5, 3, 4, 4, 1,4.25,0.85,'4/18/2026 11:18:57');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110259','DVA','GAP',1, 5, 5, 3, 2, 5, 5, 5, 5, 4, 3, 3,3.8333,0.7667,'4/18/2026 11:18:57');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110261','DVA','CO',3, 3, 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/16/2026 15:58:58');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110261','DVA','TL',5, 3, 4, 4, 5, 3, 2, 3, 5, 3, 5, 5,3.9167,0.7833,'4/16/2026 15:58:58');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110261','DVA','GAP',4, 2, 5, 5, 5, 5, 2, 5, 5, 5, 5, 3,4.25,0.85,'4/16/2026 15:58:58');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110262','DVA','CO',2, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/12/2026 15:41:07');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110262','DVA','TL',5, 5, 4, 5, 5, 5, 5, 5, 2, 2, 3, 5,4.25,0.85,'4/12/2026 15:41:07');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110262','DVA','GAP',5, 5, 4, 5, 2, 4, 5, 3, 2, 4, 5, 4,4.0,0.8,'4/12/2026 15:41:07');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110264','DVA','CO',3, 3, 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/13/2026 10:17:44');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110264','DVA','TL',4, 5, 4, 4, 4, 4, 5, 2, 4, 4, 5, 4,4.0833,0.8167,'4/13/2026 10:17:44');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110264','DVA','GAP',5, 5, 5, 5, 4, 5, 4, 4, 5, 3, 4, 5,4.5,0.9,'4/13/2026 10:17:44');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110266','DVA','CO',1, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/18/2026 14:09:43');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110266','DVA','TL',4, 4, 4, 3, 4, 3, 2, 4, 3, 5, 4, 5,3.75,0.75,'4/18/2026 14:09:43');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110266','DVA','GAP',5, 4, 1, 3, 4, 1, 3, 4, 5, 2, 4, 5,3.4167,0.6833,'4/18/2026 14:09:43');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110268','DVA','CO',3, 3, 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/15/2026 15:28:31');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110268','DVA','TL',5, 5, 2, 5, 3, 5, 5, 5, 5, 4, 5, 5,4.5,0.9,'4/15/2026 15:28:31');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110268','DVA','GAP',5, 5, 5, 1, 5, 5, 5, 3, 4, 4, 5, 3,4.1667,0.8333,'4/15/2026 15:28:31');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110269','DVA','CO',3, 2, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/13/2026 15:48:37');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110269','DVA','TL',5, 4, 5, 3, 3, 4, 2, 4, 3, 3, 3, 5,3.6667,0.7333,'4/13/2026 15:48:37');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110269','DVA','GAP',5, 2, 5, 4, 3, 5, 4, 4, 1, 3, 5, 4,3.75,0.75,'4/13/2026 15:48:37');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110270','DVA','CO',2, 1, 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,1.75,0.5833,'4/18/2026 12:44:20');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110270','DVA','TL',4, 3, 5, 4, 4, 4, 4, 3, 5, 4, 5, 2,3.9167,0.7833,'4/18/2026 12:44:20');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110270','DVA','GAP',1, 1, 3, 3, 4, 5, 2, 5, 5, 3, 3, 4,3.25,0.65,'4/18/2026 12:44:20');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110272','DVA','CO',3, 3, 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/16/2026 20:07:07');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110272','DVA','TL',5, 4, 4, 5, 3, 5, 5, 5, 5, 4, 1, 5,4.25,0.85,'4/16/2026 20:07:07');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110272','DVA','GAP',5, 3, 2, 2, 4, 4, 5, 4, 3, 5, 5, 5,3.9167,0.7833,'4/16/2026 20:07:07');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110273','DVA','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/14/2026 11:43:55');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110273','DVA','TL',3, 4, 5, 5, 5, 5, 5, 4, 5, 5, 3, 5,4.5,0.9,'4/14/2026 11:43:55');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110273','DVA','GAP',5, 4, 5, 3, 2, 3, 4, 5, 5, 4, 4, 4,4.0,0.8,'4/14/2026 11:43:55');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110275','DVA','CO',2, 3, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/17/2026 13:40:39');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110275','DVA','TL',2, 5, 5, 5, 5, 3, 5, 4, 3, 3, 5, 5,4.1667,0.8333,'4/17/2026 13:40:39');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110275','DVA','GAP',1, 4, 5, 5, 5, 5, 4, 1, 4, 4, 5, 5,4.0,0.8,'4/17/2026 13:40:39');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110276','DVA','CO',2, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/15/2026 11:20:22');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110276','DVA','TL',3, 5, 5, 5, 5, 2, 1, 5, 3, 3, 5, 4,3.8333,0.7667,'4/15/2026 11:20:22');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110276','DVA','GAP',5, 5, 5, 5, 5, 5, 5, 4, 3, 5, 5, 5,4.75,0.95,'4/15/2026 11:20:22');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110277','DVA','CO',3, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/12/2026 13:02:11');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110277','DVA','TL',3, 2, 5, 2, 2, 5, 5, 4, 5, 5, 3, 5,3.8333,0.7667,'4/12/2026 13:02:11');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110277','DVA','GAP',5, 5, 4, 4, 3, 2, 4, 4, 5, 5, 4, 3,4.0,0.8,'4/12/2026 13:02:11');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110279','DVA','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/16/2026 11:48:49');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110279','DVA','TL',5, 5, 4, 5, 3, 5, 5, 5, 4, 5, 1, 5,4.3333,0.8667,'4/16/2026 11:48:49');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110279','DVA','GAP',2, 5, 5, 4, 4, 2, 4, 5, 5, 5, 1, 3,3.75,0.75,'4/16/2026 11:48:49');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110280','DVA','CO',2, 2, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/13/2026 11:34:28');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110280','DVA','TL',3, 5, 4, 5, 5, 5, 5, 3, 2, 5, 4, 4,4.1667,0.8333,'4/13/2026 11:34:28');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110280','DVA','GAP',2, 5, 5, 4, 5, 3, 5, 4, 5, 1, 4, 4,3.9167,0.7833,'4/13/2026 11:34:28');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110281','DVA','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/13/2026 18:29:23');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110281','DVA','TL',4, 4, 2, 4, 4, 4, 4, 1, 4, 5, 5, 4,3.75,0.75,'4/13/2026 18:29:23');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110281','DVA','GAP',4, 4, 5, 5, 4, 5, 4, 5, 5, 4, 4, 5,4.5,0.9,'4/13/2026 18:29:23');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110282','DVA','CO',3, 2, 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/15/2026 10:02:59');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110282','DVA','TL',1, 5, 1, 5, 4, 3, 5, 3, 5, 5, 5, 5,3.9167,0.7833,'4/15/2026 10:02:59');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110282','DVA','GAP',4, 5, 2, 5, 5, 3, 5, 5, 5, 5, 4, 4,4.3333,0.8667,'4/15/2026 10:02:59');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110284','DVA','CO',3, 2, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/12/2026 17:08:30');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110284','DVA','TL',4, 5, 5, 5, 5, 5, 5, 5, 3, 5, 5, 5,4.75,0.95,'4/12/2026 17:08:30');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110284','DVA','GAP',3, 5, 3, 3, 5, 5, 3, 3, 5, 4, 5, 5,4.0833,0.8167,'4/12/2026 17:08:30');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110285','DVA','CO',1, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/16/2026 18:41:44');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110285','DVA','TL',4, 4, 5, 3, 5, 4, 5, 4, 3, 5, 3, 5,4.1667,0.8333,'4/16/2026 18:41:44');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110285','DVA','GAP',2, 3, 5, 4, 5, 4, 5, 1, 4, 4, 5, 5,3.9167,0.7833,'4/16/2026 18:41:44');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110287','DVA','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/15/2026 14:03:08');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110287','DVA','TL',5, 4, 5, 3, 5, 5, 5, 5, 5, 4, 5, 5,4.6667,0.9333,'4/15/2026 14:03:08');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110287','DVA','GAP',5, 4, 5, 5, 5, 2, 4, 5, 5, 1, 4, 5,4.1667,0.8333,'4/15/2026 14:03:08');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110289','DVA','CO',2, 1, 2, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,1.5,0.5,'4/12/2026 18:22:43');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110289','DVA','TL',5, 2, 5, 4, 5, 5, 5, 5, 2, 5, 5, 2,4.1667,0.8333,'4/12/2026 18:22:43');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110289','DVA','GAP',5, 5, 4, 5, 5, 5, 5, 2, 5, 5, 3, 4,4.4167,0.8833,'4/12/2026 18:22:43');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110290','DVA','CO',3, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/13/2026 20:03:46');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110290','DVA','TL',3, 4, 4, 5, 4, 5, 5, 5, 4, 4, 5, 2,4.1667,0.8333,'4/13/2026 20:03:46');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110290','DVA','GAP',2, 4, 5, 5, 4, 3, 3, 3, 5, 4, 5, 5,4.0,0.8,'4/13/2026 20:03:46');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110291','DVA','CO',3, 2, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/16/2026 17:16:21');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110291','DVA','TL',3, 4, 4, 4, 5, 4, 4, 5, 5, 4, 5, 4,4.25,0.85,'4/16/2026 17:16:21');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110291','DVA','GAP',5, 4, 5, 5, 5, 4, 4, 5, 4, 3, 3, 5,4.3333,0.8667,'4/16/2026 17:16:21');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110292','DVA','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/14/2026 9:10:09');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110292','DVA','TL',4, 5, 2, 5, 5, 3, 5, 5, 4, 5, 1, 5,4.0833,0.8167,'4/14/2026 9:10:09');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110292','DVA','GAP',4, 4, 2, 5, 5, 5, 3, 5, 4, 5, 4, 5,4.25,0.85,'4/14/2026 9:10:09');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110293','DVA','CO',1, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/17/2026 18:00:48');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110293','DVA','TL',4, 5, 4, 2, 5, 5, 5, 4, 5, 2, 4, 5,4.1667,0.8333,'4/17/2026 18:00:48');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110293','DVA','GAP',4, 5, 1, 5, 4, 4, 2, 5, 4, 5, 3, 3,3.75,0.75,'4/17/2026 18:00:48');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110295','DVA','CO',3, 1, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/12/2026 10:33:05');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110295','DVA','TL',5, 3, 4, 5, 5, 4, 4, 5, 5, 5, 5, 3,4.4167,0.8833,'4/12/2026 10:33:05');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110295','DVA','GAP',5, 5, 4, 1, 4, 5, 5, 3, 4, 5, 5, 4,4.1667,0.8333,'4/12/2026 10:33:05');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110296','DVA','CO',3, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/16/2026 13:06:12');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110296','DVA','TL',2, 3, 5, 5, 4, 5, 5, 4, 5, 4, 5, 4,4.25,0.85,'4/16/2026 13:06:12');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110296','DVA','GAP',4, 5, 4, 3, 5, 4, 4, 5, 2, 5, 3, 5,4.0833,0.8167,'4/16/2026 13:06:12');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110297','DVA','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/17/2026 9:32:30');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110297','DVA','TL',3, 4, 1, 5, 3, 4, 4, 4, 4, 5, 5, 2,3.6667,0.7333,'4/17/2026 9:32:30');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110297','DVA','GAP',4, 5, 3, 2, 5, 3, 4, 4, 3, 5, 5, 5,4.0,0.8,'4/17/2026 9:32:30');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110298','DVA','CO',3, 2, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/13/2026 17:11:00');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110298','DVA','TL',4, 5, 5, 3, 4, 3, 5, 5, 5, 5, 4, 5,4.4167,0.8833,'4/13/2026 17:11:00');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110298','DVA','GAP',5, 5, 5, 3, 3, 4, 3, 1, 5, 5, 4, 5,4.0,0.8,'4/13/2026 17:11:00');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110299','DVA','CO',3, 1, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/14/2026 13:07:18');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110299','DVA','TL',2, 5, 5, 5, 5, 4, 5, 5, 3, 4, 2, 5,4.1667,0.8333,'4/14/2026 13:07:18');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110299','DVA','GAP',5, 3, 2, 1, 5, 4, 5, 4, 5, 5, 2, 4,3.75,0.75,'4/14/2026 13:07:18');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110300','DVA','CO',3, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/17/2026 10:57:53');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110300','DVA','TL',5, 1, 1, 2, 4, 3, 2, 5, 5, 2, 5, 5,3.3333,0.6667,'4/17/2026 10:57:53');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110300','DVA','GAP',5, 5, 3, 3, 1, 5, 4, 5, 5, 1, 5, 4,3.8333,0.7667,'4/17/2026 10:57:53');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110302','DVA','CO',3, 1, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/15/2026 20:40:40');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110302','DVA','TL',4, 5, 5, 1, 5, 4, 4, 5, 5, 5, 5, 3,4.25,0.85,'4/15/2026 20:40:40');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110302','DVA','GAP',5, 2, 1, 3, 5, 5, 5, 5, 3, 5, 5, 5,4.0833,0.8167,'4/15/2026 20:40:40');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110303','DVA','CO',3, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/14/2026 15:49:04');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110303','DVA','TL',4, 5, 4, 5, 5, 4, 5, 3, 3, 4, 5, 3,4.1667,0.8333,'4/14/2026 15:49:04');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110303','DVA','GAP',5, 5, 5, 5, 5, 3, 5, 5, 5, 4, 3, 5,4.5833,0.9167,'4/14/2026 15:49:04');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110311','DVA','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/17/2026 12:15:16');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110311','DVA','TL',5, 5, 4, 5, 4, 4, 5, 4, 5, 4, 4, 3,4.3333,0.8667,'4/17/2026 12:15:16');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110311','DVA','GAP',3, 5, 5, 4, 2, 3, 3, 4, 4, 3, 5, 5,3.8333,0.7667,'4/17/2026 12:15:16');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110312','DVA','CO',3, 1, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/12/2026 9:14:22');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110312','DVA','TL',3, 4, 5, 3, 4, 3, 5, 5, 5, 5, 5, 5,4.3333,0.8667,'4/12/2026 9:14:22');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110312','DVA','GAP',5, 5, 5, 5, 2, 5, 5, 4, 4, 5, 2, 4,4.25,0.85,'4/12/2026 9:14:22');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110313','DVA','CO',3, 1, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/16/2026 14:31:35');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110313','DVA','TL',4, 4, 5, 5, 4, 2, 4, 5, 4, 2, 5, 4,4.0,0.8,'4/16/2026 14:31:35');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110313','DVA','GAP',5, 5, 5, 5, 4, 5, 3, 5, 4, 5, 5, 2,4.4167,0.8833,'4/16/2026 14:31:35');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110315','DVA','CO',3, 1, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/14/2026 20:05:13');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110315','DVA','TL',5, 5, 3, 1, 4, 4, 3, 5, 5, 5, 5, 5,4.1667,0.8333,'4/14/2026 20:05:13');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110315','DVA','GAP',5, 3, 5, 5, 5, 5, 5, 4, 5, 3, 2, 3,4.1667,0.8333,'4/14/2026 20:05:13');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110318','DVA','CO',2, 2, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/13/2026 14:22:14');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110318','DVA','TL',4, 5, 5, 5, 5, 5, 5, 2, 4, 5, 5, 5,4.5833,0.9167,'4/13/2026 14:22:14');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110318','DVA','GAP',4, 4, 5, 3, 5, 5, 4, 5, 5, 5, 4, 3,4.3333,0.8667,'4/13/2026 14:22:14');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110320','DVA','CO',3, 3, 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/15/2026 17:00:54');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110320','DVA','TL',5, 4, 5, 3, 5, 5, 5, 2, 5, 5, 5, 5,4.5,0.9,'4/15/2026 17:00:54');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110320','DVA','GAP',5, 3, 5, 5, 2, 5, 4, 5, 5, 5, 5, 5,4.5,0.9,'4/15/2026 17:00:54');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110321','DVA','CO',2, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/18/2026 17:02:29');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110321','DVA','TL',5, 5, 3, 3, 5, 2, 5, 5, 5, 3, 3, 5,4.0833,0.8167,'4/18/2026 17:02:29');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110321','DVA','GAP',4, 3, 1, 5, 3, 5, 5, 5, 5, 5, 4, 2,3.9167,0.7833,'4/18/2026 17:02:29');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110322','DVA','CO',3, 3, 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/12/2026 14:19:54');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110322','DVA','TL',5, 3, 5, 5, 5, 5, 4, 5, 5, 3, 5, 3,4.4167,0.8833,'4/12/2026 14:19:54');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110322','DVA','GAP',5, 5, 5, 5, 2, 4, 5, 5, 5, 4, 3, 5,4.4167,0.8833,'4/12/2026 14:19:54');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110325','DVA','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/17/2026 19:28:11');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110325','DVA','TL',3, 3, 5, 3, 4, 4, 4, 3, 5, 5, 1, 4,3.6667,0.7333,'4/17/2026 19:28:11');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110325','DVA','GAP',5, 3, 2, 5, 3, 3, 5, 5, 3, 5, 5, 3,3.9167,0.7833,'4/17/2026 19:28:11');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110327','DVA','CO',2, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/14/2026 14:24:41');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110327','DVA','TL',5, 4, 2, 2, 5, 4, 5, 5, 3, 5, 4, 3,3.9167,0.7833,'4/14/2026 14:24:41');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110327','DVA','GAP',4, 3, 5, 3, 1, 5, 5, 5, 5, 5, 4, 1,3.8333,0.7667,'4/14/2026 14:24:41');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110395','DVA','CO',3, 2, 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/15/2026 18:15:17');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110395','DVA','TL',3, 4, 3, 5, 4, 5, 3, 5, 4, 3, 4, 4,3.9167,0.7833,'4/15/2026 18:15:17');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110395','DVA','GAP',4, 5, 4, 5, 3, 5, 4, 5, 4, 5, 3, 5,4.3333,0.8667,'4/15/2026 18:15:17');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110462','DVA','CO',2, 1, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.0,0.6667,'4/14/2026 17:06:27');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110462','DVA','TL',5, 5, 5, 4, 4, 5, 2, 5, 5, 2, 4, 3,4.0833,0.8167,'4/14/2026 17:06:27');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110462','DVA','GAP',5, 5, 4, 4, 5, 3, 5, 2, 3, 3, 2, 5,3.8333,0.7667,'4/14/2026 17:06:27');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110581','DVA','CO',3, 3, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/13/2026 13:05:51');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110581','DVA','TL',5, 4, 5, 5, 5, 3, 5, 4, 2, 5, 1, 2,3.8333,0.7667,'4/13/2026 13:05:51');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110581','DVA','GAP',5, 5, 4, 3, 4, 3, 4, 4, 5, 3, 5, 2,3.9167,0.7833,'4/13/2026 13:05:51');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110701','DVA','CO',2, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/13/2026 8:55:02');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110701','DVA','TL',5, 5, 5, 4, 5, 5, 5, 4, 5, 5, 3, 5,4.6667,0.9333,'4/13/2026 8:55:02');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110701','DVA','GAP',4, 5, 4, 4, 5, 5, 4, 5, 5, 4, 2, 5,4.3333,0.8667,'4/13/2026 8:55:02');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110791','DVA','CO',3, 1, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/15/2026 8:47:36');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110791','DVA','TL',5, 2, 4, 5, 5, 5, 4, 5, 5, 4, 5, 3,4.3333,0.8667,'4/15/2026 8:47:36');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110791','DVA','GAP',3, 5, 3, 2, 4, 5, 4, 4, 3, 1, 5, 3,3.5,0.7,'4/15/2026 8:47:36');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120021','DVA','CO',2, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/17/2026 16:33:25');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120021','DVA','TL',4, 4, 2, 5, 5, 5, 3, 5, 3, 5, 4, 5,4.1667,0.8333,'4/17/2026 16:33:25');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120021','DVA','GAP',5, 4, 4, 5, 5, 5, 5, 4, 5, 5, 1, 5,4.4167,0.8833,'4/17/2026 16:33:25');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120025','DVA','CO',3, 2, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/16/2026 10:23:26');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120025','DVA','TL',5, 4, 2, 5, 4, 2, 3, 5, 2, 5, 5, 5,3.9167,0.7833,'4/16/2026 10:23:26');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120025','DVA','GAP',2, 4, 5, 5, 3, 5, 3, 4, 5, 4, 5, 4,4.0833,0.8167,'4/16/2026 10:23:26');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120027','DVA','CO',1, 3, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/12/2026 20:01:15');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120027','DVA','TL',5, 4, 4, 3, 5, 2, 5, 5, 3, 3, 3, 4,3.8333,0.7667,'4/12/2026 20:01:15');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120027','DVA','GAP',5, 4, 5, 5, 5, 4, 4, 4, 5, 4, 5, 1,4.25,0.85,'4/12/2026 20:01:15');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120028','DVA','CO',3, 2, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/17/2026 15:08:02');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120028','DVA','TL',5, 3, 4, 4, 3, 3, 5, 2, 5, 3, 4, 4,3.75,0.75,'4/17/2026 15:08:02');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120028','DVA','GAP',5, 5, 4, 3, 5, 3, 4, 5, 4, 5, 5, 5,4.4167,0.8833,'4/17/2026 15:08:02');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120029','DVA','CO',3, 3, 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/18/2026 9:53:34');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120029','DVA','TL',5, 1, 4, 5, 4, 3, 5, 5, 4, 4, 5, 5,4.1667,0.8333,'4/18/2026 9:53:34');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120029','DVA','GAP',3, 5, 5, 5, 5, 5, 5, 3, 5, 5, 5, 1,4.3333,0.8667,'4/18/2026 9:53:34');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120030','DVA','CO',2, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/18/2026 15:35:06');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120030','DVA','TL',5, 5, 5, 5, 5, 5, 5, 1, 4, 5, 3, 3,4.25,0.85,'4/18/2026 15:35:06');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120030','DVA','GAP',4, 5, 4, 5, 4, 3, 5, 5, 4, 3, 3, 5,4.1667,0.8333,'4/18/2026 15:35:06');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120031','DVA','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/16/2026 9:05:03');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120031','DVA','TL',4, 5, 3, 5, 4, 4, 5, 5, 5, 5, 5, 5,4.5833,0.9167,'4/16/2026 9:05:03');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120031','DVA','GAP',3, 5, 5, 5, 4, 3, 3, 2, 3, 5, 5, 4,3.9167,0.7833,'4/16/2026 9:05:03');

-- ML (59 students)
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('2211100196','ML','CO',3, 2, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/12/2026 10:56:18');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('2211100196','ML','TL',4, 5, 5, 5, 4, 4, 2, 4, 4, 5, 5, 4,4.25,0.85,'4/12/2026 10:56:18');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('2211100196','ML','GAP',5, 4, 3, 5, 4, 3, 3, 2, 2, 4, 5, 4,3.6667,0.7333,'4/12/2026 10:56:18');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110250','ML','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/14/2026 20:07:53');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110250','ML','TL',2, 4, 3, 5, 3, 5, 5, 5, 4, 4, 2, 3,3.75,0.75,'4/14/2026 20:07:53');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110250','ML','GAP',5, 3, 5, 5, 5, 5, 2, 1, 4, 1, 1, 5,3.5,0.7,'4/14/2026 20:07:53');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110256','ML','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/16/2026 20:04:47');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110256','ML','TL',5, 5, 1, 3, 5, 5, 4, 4, 5, 3, 5, 3,4.0,0.8,'4/16/2026 20:04:47');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110256','ML','GAP',5, 5, 3, 3, 5, 5, 5, 4, 3, 5, 4, 4,4.25,0.85,'4/16/2026 20:04:47');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110258','ML','CO',2, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/15/2026 13:03:25');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110258','ML','TL',4, 4, 4, 2, 4, 5, 5, 5, 5, 4, 3, 5,4.1667,0.8333,'4/15/2026 13:03:25');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110258','ML','GAP',3, 5, 5, 5, 3, 4, 3, 5, 2, 5, 5, 5,4.1667,0.8333,'4/15/2026 13:03:25');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110259','ML','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/14/2026 12:57:58');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110259','ML','TL',3, 3, 4, 5, 5, 2, 2, 4, 2, 5, 3, 5,3.5833,0.7167,'4/14/2026 12:57:58');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110259','ML','GAP',5, 4, 5, 5, 5, 4, 5, 4, 4, 2, 3, 3,4.0833,0.8167,'4/14/2026 12:57:58');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110261','ML','CO',3, 3, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/11/2026 23:14:09');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110261','ML','TL',2, 4, 5, 4, 5, 4, 4, 5, 4, 3, 5, 4,4.0833,0.8167,'4/11/2026 23:14:09');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110261','ML','GAP',3, 5, 5, 2, 3, 5, 4, 5, 3, 5, 4, 5,4.0833,0.8167,'4/11/2026 23:14:09');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110262','ML','CO',3, 2, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/17/2026 11:31:56');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110262','ML','TL',3, 4, 4, 3, 5, 3, 3, 4, 2, 2, 4, 2,3.25,0.65,'4/17/2026 11:31:56');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110262','ML','GAP',5, 2, 5, 5, 5, 4, 5, 5, 5, 5, 2, 5,4.4167,0.8833,'4/17/2026 11:31:56');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110264','ML','CO',2, 3, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/14/2026 10:01:12');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110264','ML','TL',5, 3, 5, 4, 5, 1, 5, 4, 4, 3, 3, 5,3.9167,0.7833,'4/14/2026 10:01:12');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110264','ML','GAP',5, 4, 2, 4, 5, 4, 4, 5, 5, 5, 5, 4,4.3333,0.8667,'4/14/2026 10:01:12');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110266','ML','CO',2, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/17/2026 14:24:42');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110266','ML','TL',5, 5, 3, 5, 5, 4, 1, 5, 3, 5, 5, 5,4.25,0.85,'4/17/2026 14:24:42');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110266','ML','GAP',5, 5, 5, 1, 5, 5, 5, 4, 5, 2, 5, 2,4.0833,0.8167,'4/17/2026 14:24:42');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110268','ML','CO',2, 2, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/15/2026 18:44:57');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110268','ML','TL',1, 4, 5, 3, 5, 5, 4, 3, 5, 4, 4, 4,3.9167,0.7833,'4/15/2026 18:44:57');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110268','ML','GAP',5, 4, 4, 2, 5, 4, 3, 5, 1, 4, 2, 5,3.6667,0.7333,'4/15/2026 18:44:57');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110269','ML','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/14/2026 14:26:21');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110269','ML','TL',5, 5, 4, 5, 4, 2, 5, 4, 4, 4, 3, 4,4.0833,0.8167,'4/14/2026 14:26:21');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110269','ML','GAP',4, 4, 5, 5, 5, 5, 5, 5, 5, 2, 5, 5,4.5833,0.9167,'4/14/2026 14:26:21');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110270','ML','CO',3, 1, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/17/2026 13:00:19');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110270','ML','TL',2, 4, 5, 5, 2, 1, 5, 4, 3, 5, 5, 2,3.5833,0.7167,'4/17/2026 13:00:19');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110270','ML','GAP',4, 5, 5, 4, 3, 5, 1, 5, 2, 4, 5, 3,3.8333,0.7667,'4/17/2026 13:00:19');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110272','ML','CO',3, 2, 2, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/13/2026 15:53:17');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110272','ML','TL',5, 5, 4, 5, 5, 3, 4, 5, 5, 5, 3, 4,4.4167,0.8833,'4/13/2026 15:53:17');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110272','ML','GAP',2, 5, 4, 3, 2, 3, 5, 4, 5, 1, 4, 4,3.5,0.7,'4/13/2026 15:53:17');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110273','ML','CO',3, 2, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/12/2026 15:00:27');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110273','ML','TL',5, 2, 4, 5, 4, 5, 5, 4, 4, 4, 4, 3,4.0833,0.8167,'4/12/2026 15:00:27');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110273','ML','GAP',3, 5, 5, 4, 4, 5, 4, 5, 2, 1, 3, 5,3.8333,0.7667,'4/12/2026 15:00:27');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110275','ML','CO',3, 3, 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/14/2026 17:19:07');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110275','ML','TL',5, 4, 5, 5, 5, 5, 4, 1, 5, 3, 3, 3,4.0,0.8,'4/14/2026 17:19:07');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110275','ML','GAP',5, 4, 4, 4, 5, 5, 3, 3, 1, 4, 4, 5,3.9167,0.7833,'4/14/2026 17:19:07');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110276','ML','CO',2, 2, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/17/2026 10:07:33');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110276','ML','TL',5, 4, 3, 5, 5, 5, 4, 5, 5, 4, 5, 5,4.5833,0.9167,'4/17/2026 10:07:33');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110276','ML','GAP',3, 4, 2, 4, 5, 4, 4, 5, 4, 4, 5, 5,4.0833,0.8167,'4/17/2026 10:07:33');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110277','ML','CO',2, 2, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/18/2026 10:30:37');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110277','ML','TL',4, 5, 2, 5, 1, 3, 5, 4, 5, 5, 5, 4,4.0,0.8,'4/18/2026 10:30:37');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110277','ML','GAP',5, 2, 5, 4, 3, 2, 5, 5, 2, 3, 5, 4,3.75,0.75,'4/18/2026 10:30:37');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110279','ML','CO',3, 1, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/16/2026 11:26:29');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110279','ML','TL',4, 5, 3, 1, 3, 5, 5, 5, 5, 4, 5, 5,4.1667,0.8333,'4/16/2026 11:26:29');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110279','ML','GAP',5, 5, 3, 5, 5, 4, 4, 5, 4, 5, 5, 1,4.25,0.85,'4/16/2026 11:26:29');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110280','ML','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/12/2026 8:47:32');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110280','ML','TL',5, 5, 5, 3, 2, 2, 3, 5, 3, 3, 4, 4,3.6667,0.7333,'4/12/2026 8:47:32');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110280','ML','GAP',5, 3, 4, 3, 3, 4, 5, 5, 4, 1, 5, 5,3.9167,0.7833,'4/12/2026 8:47:32');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110281','ML','CO',3, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/17/2026 8:39:10');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110281','ML','TL',5, 5, 4, 4, 5, 5, 3, 5, 5, 4, 5, 4,4.5,0.9,'4/17/2026 8:39:10');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110281','ML','GAP',1, 4, 3, 3, 3, 4, 2, 4, 2, 4, 5, 2,3.0833,0.6167,'4/17/2026 8:39:10');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110282','ML','CO',1, 3, 2, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.0,0.6667,'4/16/2026 8:33:43');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110282','ML','TL',4, 4, 5, 4, 5, 3, 4, 2, 5, 5, 2, 4,3.9167,0.7833,'4/16/2026 8:33:43');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110282','ML','GAP',5, 4, 4, 5, 2, 4, 5, 4, 4, 5, 5, 4,4.25,0.85,'4/16/2026 8:33:43');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110284','ML','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/13/2026 20:12:26');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110284','ML','TL',5, 5, 5, 4, 5, 5, 4, 5, 5, 1, 5, 4,4.4167,0.8833,'4/13/2026 20:12:26');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110284','ML','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 2, 5,4.75,0.95,'4/13/2026 20:12:26');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110285','ML','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/13/2026 14:22:54');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110285','ML','TL',4, 5, 3, 2, 4, 5, 5, 3, 4, 3, 4, 4,3.8333,0.7667,'4/13/2026 14:22:54');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110285','ML','GAP',5, 5, 4, 4, 2, 5, 4, 5, 5, 5, 5, 5,4.5,0.9,'4/13/2026 14:22:54');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110287','ML','CO',3, 3, 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/13/2026 8:30:22');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110287','ML','TL',5, 5, 5, 4, 5, 3, 4, 4, 3, 5, 5, 5,4.4167,0.8833,'4/13/2026 8:30:22');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110287','ML','GAP',4, 5, 5, 5, 5, 3, 4, 4, 4, 5, 5, 4,4.4167,0.8833,'4/13/2026 8:30:22');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110289','ML','CO',3, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/14/2026 18:43:30');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110289','ML','TL',3, 4, 5, 3, 5, 5, 5, 5, 3, 5, 3, 5,4.25,0.85,'4/14/2026 18:43:30');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110289','ML','GAP',5, 5, 5, 5, 5, 5, 3, 5, 3, 4, 5, 3,4.4167,0.8833,'4/14/2026 18:43:30');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110290','ML','CO',2, 3, 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/16/2026 17:12:01');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110290','ML','TL',5, 5, 5, 5, 4, 5, 5, 5, 5, 5, 5, 4,4.8333,0.9667,'4/16/2026 17:12:01');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110290','ML','GAP',4, 5, 5, 5, 4, 5, 3, 4, 4, 5, 5, 5,4.5,0.9,'4/16/2026 17:12:01');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110291','ML','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/17/2026 17:17:28');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110291','ML','TL',5, 2, 5, 5, 5, 4, 5, 5, 4, 5, 3, 4,4.3333,0.8667,'4/17/2026 17:17:28');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110291','ML','GAP',5, 1, 5, 5, 4, 5, 5, 5, 3, 5, 5, 5,4.4167,0.8833,'4/17/2026 17:17:28');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110292','ML','CO',3, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/15/2026 20:09:20');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110292','ML','TL',2, 3, 4, 5, 5, 5, 5, 5, 2, 5, 4, 4,4.0833,0.8167,'4/15/2026 20:09:20');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110292','ML','GAP',2, 3, 5, 4, 4, 1, 5, 4, 5, 5, 5, 5,4.0,0.8,'4/15/2026 20:09:20');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110293','ML','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/12/2026 19:41:36');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110293','ML','TL',5, 2, 4, 5, 4, 4, 3, 5, 5, 4, 3, 5,4.0833,0.8167,'4/12/2026 19:41:36');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110293','ML','GAP',3, 5, 2, 5, 1, 5, 5, 2, 4, 5, 5, 5,3.9167,0.7833,'4/12/2026 19:41:36');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110295','ML','CO',3, 3, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/17/2026 15:49:05');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110295','ML','TL',5, 5, 4, 2, 5, 5, 2, 5, 5, 4, 3, 4,4.0833,0.8167,'4/17/2026 15:49:05');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110295','ML','GAP',5, 5, 5, 5, 5, 5, 5, 3, 4, 3, 5, 4,4.5,0.9,'4/17/2026 15:49:05');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110296','ML','CO',2, 3, 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/16/2026 15:47:38');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110296','ML','TL',5, 5, 4, 5, 4, 5, 5, 3, 5, 3, 4, 5,4.4167,0.8833,'4/16/2026 15:47:38');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110296','ML','GAP',5, 4, 5, 2, 3, 5, 5, 5, 1, 5, 2, 5,3.9167,0.7833,'4/16/2026 15:47:38');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110297','ML','CO',1, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/16/2026 12:54:52');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110297','ML','TL',5, 4, 4, 4, 5, 5, 5, 5, 1, 5, 5, 1,4.0833,0.8167,'4/16/2026 12:54:52');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110297','ML','GAP',5, 4, 4, 5, 5, 1, 3, 5, 5, 4, 5, 5,4.25,0.85,'4/16/2026 12:54:52');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110298','ML','CO',3, 2, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/15/2026 15:56:11');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110298','ML','TL',4, 3, 3, 2, 3, 4, 3, 5, 4, 3, 5, 4,3.5833,0.7167,'4/15/2026 15:56:11');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110298','ML','GAP',5, 5, 1, 3, 3, 4, 4, 5, 4, 5, 5, 4,4.0,0.8,'4/15/2026 15:56:11');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110299','ML','CO',3, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/12/2026 9:22:55');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110299','ML','TL',4, 5, 5, 5, 5, 4, 4, 5, 2, 5, 5, 5,4.5,0.9,'4/12/2026 9:22:55');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110299','ML','GAP',4, 5, 3, 5, 2, 5, 5, 5, 5, 1, 2, 4,3.8333,0.7667,'4/12/2026 9:22:55');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110300','ML','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/14/2026 11:29:35');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110300','ML','TL',2, 4, 5, 5, 5, 4, 4, 4, 5, 1, 3, 4,3.8333,0.7667,'4/14/2026 11:29:35');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110300','ML','GAP',5, 5, 3, 1, 5, 5, 3, 5, 5, 4, 4, 5,4.1667,0.8333,'4/14/2026 11:29:35');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110302','ML','CO',3, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/13/2026 12:51:31');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110302','ML','TL',5, 5, 4, 4, 3, 5, 3, 5, 3, 4, 4, 4,4.0833,0.8167,'4/13/2026 12:51:31');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110302','ML','GAP',5, 4, 5, 3, 5, 4, 5, 5, 5, 5, 3, 5,4.5,0.9,'4/13/2026 12:51:31');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110303','ML','CO',2, 2, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/13/2026 18:44:03');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110303','ML','TL',4, 5, 5, 5, 5, 2, 5, 2, 3, 5, 5, 4,4.1667,0.8333,'4/13/2026 18:44:03');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110303','ML','GAP',5, 5, 4, 5, 5, 5, 3, 4, 5, 5, 5, 4,4.5833,0.9167,'4/13/2026 18:44:03');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110305','ML','CO',1, 3, 2, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,1.75,0.5833,'4/15/2026 10:06:39');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110305','ML','TL',5, 5, 5, 2, 4, 5, 5, 5, 5, 5, 2, 5,4.4167,0.8833,'4/15/2026 10:06:39');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110305','ML','GAP',2, 5, 5, 3, 4, 2, 5, 5, 4, 5, 5, 3,4.0,0.8,'4/15/2026 10:06:39');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110312','ML','CO',2, 3, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/15/2026 17:20:34');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110312','ML','TL',5, 5, 3, 5, 3, 5, 3, 5, 5, 5, 3, 1,4.0,0.8,'4/15/2026 17:20:34');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110312','ML','GAP',5, 5, 4, 5, 3, 4, 5, 5, 2, 4, 5, 5,4.3333,0.8667,'4/15/2026 17:20:34');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110313','ML','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/14/2026 8:36:49');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110313','ML','TL',2, 5, 5, 2, 4, 1, 3, 5, 4, 4, 4, 3,3.5,0.7,'4/14/2026 8:36:49');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110313','ML','GAP',4, 5, 5, 5, 5, 4, 5, 4, 4, 5, 5, 1,4.3333,0.8667,'4/14/2026 8:36:49');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110315','ML','CO',3, 3, 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/18/2026 9:06:14');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110315','ML','TL',3, 5, 3, 4, 5, 5, 5, 5, 3, 3, 3, 4,4.0,0.8,'4/18/2026 9:06:14');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110315','ML','GAP',5, 1, 5, 5, 4, 5, 5, 5, 5, 5, 5, 5,4.5833,0.9167,'4/18/2026 9:06:14');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110318','ML','CO',3, 3, 2, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/11/2026 22:05:13');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110318','ML','TL',5, 4, 5, 5, 4, 5, 5, 5, 2, 5, 3, 4,4.3333,0.8667,'4/11/2026 22:05:13');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110318','ML','GAP',5, 5, 3, 2, 5, 5, 4, 3, 5, 5, 5, 5,4.3333,0.8667,'4/11/2026 22:05:13');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110320','ML','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/11/2026 22:31:46');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110320','ML','TL',5, 4, 4, 5, 5, 5, 4, 4, 3, 5, 2, 5,4.25,0.85,'4/11/2026 22:31:46');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110320','ML','GAP',5, 4, 5, 5, 5, 4, 4, 3, 5, 5, 5, 5,4.5833,0.9167,'4/11/2026 22:31:46');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110321','ML','CO',3, 2, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/15/2026 14:27:48');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110321','ML','TL',3, 4, 5, 2, 5, 5, 3, 2, 5, 5, 5, 4,4.0,0.8,'4/15/2026 14:27:48');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110321','ML','GAP',4, 3, 3, 4, 4, 5, 4, 5, 3, 5, 3, 5,4.0,0.8,'4/15/2026 14:27:48');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110322','ML','CO',3, 3, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/14/2026 15:50:44');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110322','ML','TL',5, 4, 3, 4, 5, 5, 5, 4, 2, 5, 5, 5,4.3333,0.8667,'4/14/2026 15:50:44');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110322','ML','GAP',5, 5, 3, 4, 3, 5, 1, 4, 5, 3, 3, 4,3.75,0.75,'4/14/2026 15:50:44');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110325','ML','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/15/2026 11:35:02');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110325','ML','TL',5, 4, 5, 5, 3, 5, 3, 5, 3, 5, 4, 1,4.0,0.8,'4/15/2026 11:35:02');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110325','ML','GAP',2, 5, 5, 4, 5, 4, 1, 5, 4, 5, 5, 4,4.0833,0.8167,'4/15/2026 11:35:02');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110327','ML','CO',2, 1, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/16/2026 14:19:15');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110327','ML','TL',5, 3, 4, 5, 5, 5, 5, 3, 1, 5, 5, 5,4.25,0.85,'4/16/2026 14:19:15');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110327','ML','GAP',5, 3, 3, 5, 5, 3, 5, 2, 5, 5, 3, 5,4.0833,0.8167,'4/16/2026 14:19:15');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110395','ML','CO',3, 2, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/17/2026 18:41:51');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110395','ML','TL',4, 4, 4, 5, 5, 5, 5, 2, 2, 4, 5, 5,4.1667,0.8333,'4/17/2026 18:41:51');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110395','ML','GAP',4, 4, 5, 4, 3, 1, 4, 5, 5, 5, 3, 5,4.0,0.8,'4/17/2026 18:41:51');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110462','ML','CO',3, 2, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/12/2026 12:03:41');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110462','ML','TL',5, 5, 2, 5, 4, 5, 2, 4, 5, 4, 5, 5,4.25,0.85,'4/12/2026 12:03:41');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110462','ML','GAP',3, 4, 5, 1, 5, 5, 5, 5, 5, 1, 4, 5,4.0,0.8,'4/12/2026 12:03:41');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110581','ML','CO',3, 1, 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.0,0.6667,'4/12/2026 16:44:50');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110581','ML','TL',4, 5, 4, 5, 5, 4, 3, 4, 3, 5, 4, 5,4.25,0.85,'4/12/2026 16:44:50');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110581','ML','GAP',2, 5, 3, 5, 5, 4, 5, 3, 5, 3, 5, 5,4.1667,0.8333,'4/12/2026 16:44:50');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110701','ML','CO',3, 3, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/16/2026 18:40:24');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110701','ML','TL',3, 3, 5, 1, 3, 3, 5, 4, 5, 4, 3, 1,3.3333,0.6667,'4/16/2026 18:40:24');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110701','ML','GAP',5, 5, 5, 5, 4, 5, 5, 3, 3, 4, 3, 5,4.3333,0.8667,'4/16/2026 18:40:24');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110791','ML','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/13/2026 9:58:45');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110791','ML','TL',2, 3, 5, 4, 4, 5, 5, 5, 5, 5, 4, 4,4.25,0.85,'4/13/2026 9:58:45');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110791','ML','GAP',3, 4, 5, 5, 5, 2, 5, 2, 2, 5, 4, 3,3.75,0.75,'4/13/2026 9:58:45');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120021','ML','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/16/2026 10:02:06');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120021','ML','TL',5, 4, 3, 4, 5, 5, 5, 4, 5, 4, 5, 4,4.4167,0.8833,'4/16/2026 10:02:06');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120021','ML','GAP',5, 4, 4, 4, 5, 5, 1, 4, 2, 4, 5, 3,3.8333,0.7667,'4/16/2026 10:02:06');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120025','ML','CO',3, 2, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/12/2026 21:07:59');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120025','ML','TL',5, 5, 5, 4, 4, 5, 5, 3, 3, 5, 5, 4,4.4167,0.8833,'4/12/2026 21:07:59');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120025','ML','GAP',5, 4, 5, 4, 5, 4, 2, 5, 5, 5, 3, 5,4.3333,0.8667,'4/12/2026 21:07:59');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120027','ML','CO',1, 2, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/12/2026 13:29:04');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120027','ML','TL',5, 5, 3, 5, 5, 5, 5, 3, 1, 3, 5, 4,4.0833,0.8167,'4/12/2026 13:29:04');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120027','ML','GAP',5, 5, 2, 4, 5, 5, 4, 3, 5, 5, 4, 3,4.1667,0.8333,'4/12/2026 13:29:04');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120028','ML','CO',3, 3, 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/12/2026 18:09:13');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120028','ML','TL',4, 3, 5, 4, 4, 5, 5, 5, 3, 5, 5, 3,4.25,0.85,'4/12/2026 18:09:13');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120028','ML','GAP',5, 3, 5, 4, 5, 3, 3, 5, 2, 4, 4, 4,3.9167,0.7833,'4/12/2026 18:09:13');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120029','ML','CO',3, 2, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/13/2026 17:15:40');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120029','ML','TL',2, 4, 5, 5, 3, 5, 5, 4, 5, 5, 4, 3,4.1667,0.8333,'4/13/2026 17:15:40');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120029','ML','GAP',4, 4, 3, 5, 3, 1, 5, 5, 3, 5, 3, 2,3.5833,0.7167,'4/13/2026 17:15:40');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120030','ML','CO',3, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/15/2026 8:42:16');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120030','ML','TL',5, 5, 3, 4, 5, 2, 4, 5, 5, 5, 4, 5,4.3333,0.8667,'4/15/2026 8:42:16');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120030','ML','GAP',3, 5, 2, 2, 5, 4, 4, 5, 5, 3, 1, 4,3.5833,0.7167,'4/15/2026 8:42:16');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120031','ML','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/13/2026 11:27:08');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120031','ML','TL',5, 5, 4, 5, 5, 5, 5, 5, 5, 5, 5, 3,4.75,0.95,'4/13/2026 11:27:08');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120031','ML','GAP',5, 4, 5, 5, 5, 3, 4, 4, 4, 5, 5, 5,4.5,0.9,'4/13/2026 11:27:08');

-- SE (59 students)
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('2211100196','SE','CO',3, 1, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/15/2026 16:52:55');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('2211100196','SE','TL',4, 4, 3, 5, 4, 5, 2, 4, 5, 2, 5, 5,4.0,0.8,'4/15/2026 16:52:55');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('2211100196','SE','GAP',4, 4, 5, 5, 1, 4, 1, 5, 5, 4, 2, 5,3.75,0.75,'4/15/2026 16:52:55');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110256','SE','CO',3, 3, 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/15/2026 11:15:23');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110256','SE','TL',4, 5, 5, 4, 5, 3, 5, 2, 1, 5, 4, 3,3.8333,0.7667,'4/15/2026 11:15:23');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110256','SE','GAP',5, 5, 5, 4, 4, 4, 3, 3, 5, 5, 4, 5,4.3333,0.8667,'4/15/2026 11:15:23');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110258','SE','CO',3, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/16/2026 15:07:59');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110258','SE','TL',5, 2, 5, 5, 5, 2, 5, 5, 5, 5, 1, 4,4.0833,0.8167,'4/16/2026 15:07:59');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110258','SE','GAP',5, 5, 5, 5, 4, 4, 4, 4, 4, 5, 4, 5,4.5,0.9,'4/16/2026 15:07:59');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110259','SE','CO',3, 1, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/14/2026 18:37:51');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110259','SE','TL',4, 5, 4, 3, 4, 5, 3, 5, 5, 4, 4, 5,4.25,0.85,'4/14/2026 18:37:51');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110259','SE','GAP',5, 5, 5, 5, 5, 1, 4, 5, 5, 4, 5, 5,4.5,0.9,'4/14/2026 18:37:51');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110261','SE','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/14/2026 20:02:14');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110261','SE','TL',5, 5, 3, 4, 5, 5, 4, 4, 5, 5, 4, 5,4.5,0.9,'4/14/2026 20:02:14');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110261','SE','GAP',5, 5, 3, 5, 4, 5, 3, 5, 5, 5, 5, 4,4.5,0.9,'4/14/2026 20:02:14');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110262','SE','CO',3, 2, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/17/2026 10:09:54');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110262','SE','TL',4, 4, 5, 2, 5, 2, 2, 2, 5, 4, 4, 1,3.3333,0.6667,'4/17/2026 10:09:54');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110262','SE','GAP',4, 5, 4, 5, 3, 5, 5, 4, 5, 3, 4, 5,4.3333,0.8667,'4/17/2026 10:09:54');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110264','SE','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/13/2026 9:32:06');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110264','SE','TL',5, 5, 5, 5, 3, 3, 2, 4, 5, 4, 5, 4,4.1667,0.8333,'4/13/2026 9:32:06');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110264','SE','GAP',5, 5, 4, 3, 4, 5, 5, 4, 3, 5, 5, 3,4.25,0.85,'4/13/2026 9:32:06');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110266','SE','CO',3, 3, 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/14/2026 11:35:56');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110266','SE','TL',3, 5, 5, 5, 3, 5, 5, 4, 5, 5, 5, 4,4.5,0.9,'4/14/2026 11:35:56');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110266','SE','GAP',4, 5, 5, 4, 5, 4, 5, 5, 3, 5, 4, 2,4.25,0.85,'4/14/2026 11:35:56');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110268','SE','CO',2, 3, 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/14/2026 15:49:05');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110268','SE','TL',4, 5, 5, 3, 5, 3, 4, 3, 5, 5, 3, 5,4.1667,0.8333,'4/14/2026 15:49:05');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110268','SE','GAP',5, 4, 4, 5, 3, 5, 3, 5, 3, 3, 5, 3,4.0,0.8,'4/14/2026 15:49:05');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110269','SE','CO',2, 2, 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.0,0.6667,'4/13/2026 16:34:01');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110269','SE','TL',5, 5, 4, 5, 4, 5, 5, 4, 5, 3, 5, 4,4.5,0.9,'4/13/2026 16:34:01');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110269','SE','GAP',5, 5, 5, 5, 5, 5, 3, 5, 5, 4, 4, 3,4.5,0.9,'4/13/2026 16:34:01');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110270','SE','CO',3, 3, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/17/2026 14:23:03');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110270','SE','TL',4, 3, 5, 5, 4, 5, 5, 2, 2, 5, 5, 5,4.1667,0.8333,'4/17/2026 14:23:03');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110270','SE','GAP',5, 5, 4, 5, 2, 4, 5, 4, 4, 5, 5, 5,4.4167,0.8833,'4/17/2026 14:23:03');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110272','SE','CO',3, 3, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/12/2026 16:30:11');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110272','SE','TL',5, 5, 5, 4, 5, 5, 4, 2, 4, 5, 5, 4,4.4167,0.8833,'4/12/2026 16:30:11');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110272','SE','GAP',5, 5, 4, 5, 5, 5, 4, 4, 5, 5, 1, 5,4.4167,0.8833,'4/12/2026 16:30:11');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110273','SE','CO',3, 2, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/15/2026 12:39:46');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110273','SE','TL',4, 5, 4, 5, 5, 3, 2, 3, 4, 3, 5, 5,4.0,0.8,'4/15/2026 12:39:46');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110273','SE','GAP',4, 3, 5, 5, 5, 1, 3, 4, 3, 5, 4, 3,3.75,0.75,'4/15/2026 12:39:46');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110275','SE','CO',3, 3, 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/13/2026 19:22:47');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110275','SE','TL',5, 5, 4, 5, 5, 5, 5, 4, 4, 5, 5, 3,4.5833,0.9167,'4/13/2026 19:22:47');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110275','SE','GAP',4, 5, 5, 4, 3, 3, 5, 5, 4, 4, 5, 4,4.25,0.85,'4/13/2026 19:22:47');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110276','SE','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/16/2026 8:06:04');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110276','SE','TL',3, 5, 4, 5, 5, 5, 4, 5, 2, 5, 2, 3,4.0,0.8,'4/16/2026 8:06:04');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110276','SE','GAP',5, 5, 3, 2, 3, 4, 5, 4, 4, 5, 5, 5,4.1667,0.8333,'4/16/2026 8:06:04');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110277','SE','CO',3, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/16/2026 9:30:27');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110277','SE','TL',2, 5, 5, 3, 5, 3, 4, 3, 5, 5, 4, 3,3.9167,0.7833,'4/16/2026 9:30:27');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110277','SE','GAP',3, 5, 4, 5, 4, 4, 5, 5, 4, 4, 4, 5,4.3333,0.8667,'4/16/2026 9:30:27');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110279','SE','CO',2, 3, 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.0,0.6667,'4/15/2026 18:17:18');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110279','SE','TL',5, 3, 5, 2, 5, 4, 3, 5, 4, 5, 5, 2,4.0,0.8,'4/15/2026 18:17:18');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110279','SE','GAP',5, 5, 4, 4, 3, 1, 5, 5, 5, 1, 4, 5,3.9167,0.7833,'4/15/2026 18:17:18');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110280','SE','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/12/2026 12:17:02');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110280','SE','TL',5, 3, 2, 4, 5, 4, 5, 4, 5, 5, 4, 5,4.25,0.85,'4/12/2026 12:17:02');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110280','SE','GAP',3, 3, 4, 4, 3, 3, 3, 1, 5, 5, 4, 5,3.5833,0.7167,'4/12/2026 12:17:02');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110281','SE','CO',3, 3, 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/17/2026 17:11:49');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110281','SE','TL',2, 5, 5, 2, 4, 5, 5, 4, 5, 4, 4, 5,4.1667,0.8333,'4/17/2026 17:11:49');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110281','SE','GAP',5, 2, 3, 3, 5, 4, 5, 3, 3, 4, 5, 1,3.5833,0.7167,'4/17/2026 17:11:49');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110282','SE','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/14/2026 8:47:10');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110282','SE','TL',5, 5, 5, 5, 5, 5, 4, 5, 5, 2, 5, 3,4.5,0.9,'4/14/2026 8:47:10');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110282','SE','GAP',4, 5, 5, 5, 3, 2, 5, 4, 3, 5, 5, 4,4.1667,0.8333,'4/14/2026 8:47:10');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110284','SE','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/17/2026 11:34:17');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110284','SE','TL',4, 5, 5, 3, 5, 4, 3, 5, 4, 5, 5, 5,4.4167,0.8833,'4/17/2026 11:34:17');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110284','SE','GAP',5, 1, 2, 5, 5, 5, 2, 5, 1, 5, 5, 5,3.8333,0.7667,'4/17/2026 11:34:17');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110285','SE','CO',3, 3, 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/15/2026 15:28:32');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110285','SE','TL',4, 4, 5, 3, 5, 4, 3, 3, 3, 4, 1, 5,3.6667,0.7333,'4/15/2026 15:28:32');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110285','SE','GAP',3, 5, 5, 5, 4, 5, 5, 2, 5, 5, 3, 5,4.3333,0.8667,'4/15/2026 15:28:32');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110287','SE','CO',3, 3, 2, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/13/2026 10:56:29');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110287','SE','TL',5, 4, 2, 2, 4, 4, 5, 5, 4, 5, 5, 2,3.9167,0.7833,'4/13/2026 10:56:29');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110287','SE','GAP',5, 3, 4, 2, 5, 4, 5, 4, 5, 3, 4, 2,3.8333,0.7667,'4/13/2026 10:56:29');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110289','SE','CO',3, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/12/2026 17:54:34');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110289','SE','TL',5, 3, 4, 3, 2, 5, 1, 5, 5, 4, 3, 1,3.4167,0.6833,'4/12/2026 17:54:34');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110289','SE','GAP',4, 5, 5, 4, 5, 5, 5, 5, 2, 4, 5, 5,4.5,0.9,'4/12/2026 17:54:34');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110290','SE','CO',2, 3, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/13/2026 8:07:43');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110290','SE','TL',4, 5, 4, 4, 5, 5, 5, 5, 5, 5, 3, 5,4.5833,0.9167,'4/13/2026 8:07:43');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110290','SE','GAP',5, 4, 1, 5, 4, 5, 5, 4, 3, 5, 5, 3,4.0833,0.8167,'4/13/2026 8:07:43');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110291','SE','CO',3, 2, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/14/2026 10:11:33');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110291','SE','TL',2, 4, 5, 2, 3, 5, 3, 5, 3, 5, 4, 5,3.8333,0.7667,'4/14/2026 10:11:33');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110291','SE','GAP',5, 5, 5, 5, 4, 4, 5, 1, 5, 5, 2, 5,4.25,0.85,'4/14/2026 10:11:33');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110292','SE','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/12/2026 9:28:16');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110292','SE','TL',4, 2, 4, 5, 5, 5, 3, 4, 5, 3, 5, 4,4.0833,0.8167,'4/12/2026 9:28:16');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110292','SE','GAP',5, 5, 5, 1, 5, 5, 5, 5, 3, 3, 5, 5,4.3333,0.8667,'4/12/2026 9:28:16');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110293','SE','CO',3, 2, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/11/2026 21:58:44');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110293','SE','TL',5, 4, 5, 4, 5, 2, 4, 4, 4, 5, 5, 5,4.3333,0.8667,'4/11/2026 21:58:44');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110293','SE','GAP',5, 5, 2, 4, 3, 5, 5, 5, 5, 3, 1, 5,4.0,0.8,'4/11/2026 21:58:44');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110295','SE','CO',3, 1, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/14/2026 13:00:19');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110295','SE','TL',5, 3, 4, 5, 4, 3, 4, 5, 5, 3, 5, 4,4.1667,0.8333,'4/14/2026 13:00:19');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110295','SE','GAP',5, 5, 5, 4, 4, 4, 5, 4, 4, 5, 4, 5,4.5,0.9,'4/14/2026 13:00:19');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110296','SE','CO',3, 3, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/14/2026 17:13:28');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110296','SE','TL',3, 5, 5, 3, 1, 3, 4, 5, 4, 5, 5, 5,4.0,0.8,'4/14/2026 17:13:28');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110296','SE','GAP',4, 5, 5, 2, 2, 4, 5, 4, 5, 3, 4, 5,4.0,0.8,'4/14/2026 17:13:28');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110297','SE','CO',2, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/17/2026 12:58:40');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110297','SE','TL',5, 5, 4, 3, 3, 3, 5, 5, 5, 5, 4, 4,4.25,0.85,'4/17/2026 12:58:40');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110297','SE','GAP',5, 5, 4, 3, 5, 4, 4, 5, 5, 5, 4, 1,4.1667,0.8333,'4/17/2026 12:58:40');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110298','SE','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/16/2026 19:21:08');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110298','SE','TL',4, 5, 3, 5, 3, 5, 5, 5, 3, 2, 2, 3,3.75,0.75,'4/16/2026 19:21:08');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110298','SE','GAP',4, 4, 5, 4, 5, 3, 5, 1, 5, 3, 5, 1,3.75,0.75,'4/16/2026 19:21:08');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110299','SE','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/17/2026 18:36:12');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110299','SE','TL',4, 5, 1, 5, 5, 5, 4, 3, 5, 5, 4, 5,4.25,0.85,'4/17/2026 18:36:12');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110299','SE','GAP',4, 3, 2, 5, 5, 3, 2, 4, 5, 3, 4, 5,3.75,0.75,'4/17/2026 18:36:12');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110300','SE','CO',3, 1, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/12/2026 10:52:39');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110300','SE','TL',5, 5, 4, 3, 5, 5, 2, 5, 4, 5, 5, 4,4.3333,0.8667,'4/12/2026 10:52:39');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110300','SE','GAP',5, 4, 5, 3, 3, 4, 5, 5, 5, 4, 3, 5,4.25,0.85,'4/12/2026 10:52:39');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110302','SE','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/17/2026 15:47:26');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110302','SE','TL',4, 5, 4, 5, 4, 5, 1, 4, 2, 2, 5, 5,3.8333,0.7667,'4/17/2026 15:47:26');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110302','SE','GAP',5, 5, 3, 5, 4, 5, 5, 2, 5, 3, 4, 5,4.25,0.85,'4/17/2026 15:47:26');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110303','SE','CO',3, 2, 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/12/2026 20:43:20');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110303','SE','TL',5, 5, 5, 5, 5, 5, 5, 5, 3, 5, 5, 5,4.8333,0.9667,'4/12/2026 20:43:20');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110303','SE','GAP',5, 2, 3, 4, 5, 3, 5, 5, 2, 5, 4, 4,3.9167,0.7833,'4/12/2026 20:43:20');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110305','SE','CO',2, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/16/2026 10:54:50');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110305','SE','TL',5, 4, 5, 2, 5, 5, 5, 4, 5, 1, 5, 5,4.25,0.85,'4/16/2026 10:54:50');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110305','SE','GAP',5, 5, 5, 5, 4, 4, 4, 4, 5, 5, 4, 2,4.3333,0.8667,'4/16/2026 10:54:50');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110311','SE','CO',3, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/12/2026 8:51:53');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110311','SE','TL',2, 4, 4, 4, 5, 4, 4, 5, 5, 5, 5, 5,4.3333,0.8667,'4/12/2026 8:51:53');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110311','SE','GAP',4, 5, 2, 5, 3, 1, 5, 3, 3, 4, 4, 5,3.6667,0.7333,'4/12/2026 8:51:53');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110312','SE','CO',2, 3, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/12/2026 19:18:57');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110312','SE','TL',5, 3, 5, 5, 4, 4, 5, 5, 5, 5, 2, 5,4.4167,0.8833,'4/12/2026 19:18:57');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110312','SE','GAP',4, 5, 5, 4, 1, 5, 5, 5, 5, 5, 2, 5,4.25,0.85,'4/12/2026 19:18:57');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110313','SE','CO',3, 2, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/13/2026 15:09:38');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110313','SE','TL',2, 5, 3, 2, 5, 1, 4, 4, 5, 3, 1, 5,3.3333,0.6667,'4/13/2026 15:09:38');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110313','SE','GAP',3, 4, 3, 4, 3, 5, 5, 5, 2, 4, 5, 5,4.0,0.8,'4/13/2026 15:09:38');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110315','SE','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/13/2026 17:58:24');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110315','SE','TL',5, 4, 3, 5, 5, 3, 3, 3, 3, 5, 5, 3,3.9167,0.7833,'4/13/2026 17:58:24');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110315','SE','GAP',3, 3, 4, 5, 1, 5, 5, 5, 3, 3, 5, 5,3.9167,0.7833,'4/13/2026 17:58:24');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110318','SE','CO',3, 3, 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/16/2026 16:32:22');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110318','SE','TL',5, 5, 5, 5, 5, 2, 5, 4, 5, 5, 5, 4,4.5833,0.9167,'4/16/2026 16:32:22');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110318','SE','GAP',4, 5, 2, 5, 5, 5, 2, 4, 5, 1, 5, 4,3.9167,0.7833,'4/16/2026 16:32:22');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110320','SE','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/11/2026 22:24:07');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110320','SE','TL',5, 5, 5, 5, 5, 5, 4, 3, 5, 4, 5, 4,4.5833,0.9167,'4/11/2026 22:24:07');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110320','SE','GAP',3, 4, 5, 5, 5, 5, 4, 4, 5, 2, 3, 5,4.1667,0.8333,'4/11/2026 22:24:07');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110321','SE','CO',2, 2, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/16/2026 12:19:13');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110321','SE','TL',3, 5, 5, 3, 4, 5, 5, 5, 5, 5, 4, 4,4.4167,0.8833,'4/16/2026 12:19:13');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110321','SE','GAP',5, 5, 4, 5, 4, 1, 4, 5, 4, 5, 4, 5,4.25,0.85,'4/16/2026 12:19:13');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110322','SE','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/14/2026 14:24:42');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110322','SE','TL',5, 4, 4, 5, 5, 5, 5, 5, 5, 5, 4, 3,4.5833,0.9167,'4/14/2026 14:24:42');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110322','SE','GAP',4, 5, 1, 5, 5, 1, 5, 3, 5, 3, 5, 5,3.9167,0.7833,'4/14/2026 14:24:42');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110325','SE','CO',3, 3, 2, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/12/2026 15:05:48');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110325','SE','TL',5, 4, 1, 3, 5, 1, 4, 2, 5, 5, 2, 5,3.5,0.7,'4/12/2026 15:05:48');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110325','SE','GAP',5, 3, 5, 3, 2, 5, 5, 4, 5, 3, 2, 5,3.9167,0.7833,'4/12/2026 15:05:48');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110327','SE','CO',3, 2, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/12/2026 13:41:25');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110327','SE','TL',4, 2, 5, 5, 4, 5, 3, 5, 5, 5, 5, 5,4.4167,0.8833,'4/12/2026 13:41:25');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110327','SE','GAP',4, 5, 5, 3, 5, 4, 5, 5, 4, 4, 5, 5,4.5,0.9,'4/12/2026 13:41:25');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110395','SE','CO',2, 3, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/15/2026 9:51:00');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110395','SE','TL',5, 5, 5, 4, 3, 5, 5, 4, 4, 3, 4, 4,4.25,0.85,'4/15/2026 9:51:00');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110395','SE','GAP',4, 2, 3, 3, 5, 5, 5, 5, 5, 5, 5, 4,4.25,0.85,'4/15/2026 9:51:00');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110462','SE','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/13/2026 12:20:52');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110462','SE','TL',4, 4, 4, 5, 4, 5, 5, 5, 5, 5, 5, 5,4.6667,0.9333,'4/13/2026 12:20:52');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110462','SE','GAP',4, 5, 5, 4, 3, 4, 2, 2, 5, 5, 5, 4,4.0,0.8,'4/13/2026 12:20:52');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110581','SE','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/15/2026 8:26:37');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110581','SE','TL',4, 4, 3, 5, 3, 5, 5, 5, 3, 5, 2, 1,3.75,0.75,'4/15/2026 8:26:37');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110581','SE','GAP',1, 5, 5, 5, 5, 5, 5, 5, 3, 4, 3, 5,4.25,0.85,'4/15/2026 8:26:37');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110701','SE','CO',2, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/18/2026 9:00:35');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110701','SE','TL',5, 4, 5, 5, 4, 3, 5, 5, 5, 5, 5, 4,4.5833,0.9167,'4/18/2026 9:00:35');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110701','SE','GAP',3, 5, 5, 5, 5, 2, 3, 4, 2, 3, 3, 5,3.75,0.75,'4/18/2026 9:00:35');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110791','SE','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/17/2026 8:45:31');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110791','SE','TL',2, 5, 5, 5, 5, 5, 4, 5, 4, 2, 5, 5,4.3333,0.8667,'4/17/2026 8:45:31');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110791','SE','GAP',4, 4, 5, 5, 4, 3, 5, 4, 5, 5, 5, 5,4.5,0.9,'4/17/2026 8:45:31');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120021','SE','CO',2, 3, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/15/2026 14:04:09');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120021','SE','TL',5, 4, 4, 4, 4, 5, 4, 5, 5, 5, 5, 3,4.4167,0.8833,'4/15/2026 14:04:09');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120021','SE','GAP',4, 2, 1, 5, 3, 5, 3, 2, 2, 4, 4, 3,3.1667,0.6333,'4/15/2026 14:04:09');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120025','SE','CO',2, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/16/2026 17:56:45');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120025','SE','TL',4, 4, 5, 5, 1, 4, 3, 4, 4, 4, 3, 4,3.75,0.75,'4/16/2026 17:56:45');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120025','SE','GAP',1, 4, 4, 4, 5, 5, 4, 5, 4, 2, 4, 3,3.75,0.75,'4/16/2026 17:56:45');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120027','SE','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/15/2026 19:41:41');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120027','SE','TL',2, 5, 5, 5, 5, 4, 5, 4, 3, 3, 4, 4,4.0833,0.8167,'4/15/2026 19:41:41');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120027','SE','GAP',5, 5, 5, 4, 4, 3, 5, 5, 5, 4, 4, 5,4.5,0.9,'4/15/2026 19:41:41');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120028','SE','CO',2, 1, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.25,0.75,'4/18/2026 10:24:58');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120028','SE','TL',4, 5, 5, 2, 4, 4, 5, 3, 4, 3, 3, 4,3.8333,0.7667,'4/18/2026 10:24:58');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120028','SE','GAP',4, 5, 3, 5, 5, 3, 4, 4, 5, 5, 5, 4,4.3333,0.8667,'4/18/2026 10:24:58');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120029','SE','CO',2, 2, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/11/2026 23:07:30');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120029','SE','TL',4, 5, 5, 4, 5, 5, 5, 3, 4, 3, 5, 4,4.3333,0.8667,'4/11/2026 23:07:30');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120029','SE','GAP',4, 1, 3, 5, 3, 2, 5, 5, 5, 2, 2, 5,3.5,0.7,'4/11/2026 23:07:30');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120030','SE','CO',3, 3, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/13/2026 13:45:15');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120030','SE','TL',5, 4, 4, 4, 5, 1, 5, 5, 2, 2, 4, 4,3.75,0.75,'4/13/2026 13:45:15');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120030','SE','GAP',5, 5, 5, 5, 4, 5, 5, 1, 5, 3, 3, 3,4.0833,0.8167,'4/13/2026 13:45:15');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120031','SE','CO',1, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/16/2026 13:43:36');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120031','SE','TL',5, 5, 5, 5, 2, 5, 4, 5, 4, 3, 4, 5,4.3333,0.8667,'4/16/2026 13:43:36');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120031','SE','GAP',4, 5, 5, 4, 3, 3, 5, 4, 5, 4, 4, 5,4.25,0.85,'4/16/2026 13:43:36');

-- TOC (60 students)
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('2211100196','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/17/2026 10:16:21');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('2211100196','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/17/2026 10:16:21');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('2211100196','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/17/2026 10:16:21');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110250','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/15/2026 10:57:00');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110250','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/15/2026 10:57:00');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110250','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/15/2026 10:57:00');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110256','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/14/2026 15:06:09');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110256','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/14/2026 15:06:09');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110256','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/14/2026 15:06:09');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110258','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/14/2026 19:19:22');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110258','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/14/2026 19:19:22');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110258','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/14/2026 19:19:22');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110259','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/13/2026 10:48:50');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110259','TOC','TL',4, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,3.0833,0.6167,'4/13/2026 10:48:50');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110259','TOC','GAP',3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,3.0,0.6,'4/13/2026 10:48:50');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110261','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/16/2026 13:49:54');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110261','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/16/2026 13:49:54');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110261','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/16/2026 13:49:54');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110262','TOC','CO',3, 2, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/15/2026 19:23:27');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110262','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/15/2026 19:23:27');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110262','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/15/2026 19:23:27');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110264','TOC','CO',3, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/15/2026 16:34:38');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110264','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/15/2026 16:34:38');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110264','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/15/2026 16:34:38');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110266','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/13/2026 15:02:04');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110266','TOC','TL',5, 4, 5, 5, 5, 5, 4, 5, 5, 5, 5, 5,4.8333,0.9667,'4/13/2026 15:02:04');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110266','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/13/2026 15:02:04');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110268','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/16/2026 11:01:05');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110268','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/16/2026 11:01:05');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110268','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/16/2026 11:01:05');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110269','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/13/2026 20:39:42');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110269','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/13/2026 20:39:42');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110269','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/13/2026 20:39:42');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110270','TOC','CO',2, 2, 2, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.0,0.6667,'4/15/2026 12:21:25');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110270','TOC','TL',4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,4.0,0.8,'4/15/2026 12:21:25');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110270','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/15/2026 12:21:25');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110272','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/14/2026 13:41:44');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110272','TOC','TL',4, 4, 4, 3, 4, 5, 4, 4, 4, 4, 4, 4,4.0,0.8,'4/14/2026 13:41:44');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110272','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/14/2026 13:41:44');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110273','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/13/2026 19:15:17');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110273','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/13/2026 19:15:17');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110273','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/13/2026 19:15:17');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110275','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/11/2026 21:52:18');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110275','TOC','TL',4, 4, 5, 4, 5, 5, 5, 5, 5, 5, 5, 4,4.6667,0.9333,'4/11/2026 21:52:18');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110275','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/11/2026 21:52:18');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110276','TOC','CO',3, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/15/2026 20:47:52');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110276','TOC','TL',4, 3, 4, 4, 3, 3, 4, 3, 3, 4, 4, 5,3.6667,0.7333,'4/15/2026 20:47:52');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110276','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 4, 4, 5, 5,4.8333,0.9667,'4/15/2026 20:47:52');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110277','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/13/2026 13:37:39');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110277','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/13/2026 13:37:39');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110277','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/13/2026 13:37:39');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110279','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/12/2026 12:08:10');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110279','TOC','TL',4, 4, 4, 4, 3, 4, 3, 3, 4, 3, 4, 3,3.5833,0.7167,'4/12/2026 12:08:10');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110279','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/12/2026 12:08:10');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110280','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/16/2026 15:14:19');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110280','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/16/2026 15:14:19');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110280','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/16/2026 15:14:19');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110281','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/17/2026 8:51:57');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110281','TOC','TL',5, 5, 5, 4, 4, 4, 4, 4, 4, 5, 4, 5,4.4167,0.8833,'4/17/2026 8:51:57');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110281','TOC','GAP',5, 5, 5, 5, 5, 4, 5, 5, 4, 4, 5, 5,4.75,0.95,'4/17/2026 8:51:57');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110282','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/11/2026 22:08:43');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110282','TOC','TL',5, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,4.9167,0.9833,'4/11/2026 22:08:43');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110282','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/11/2026 22:08:43');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110284','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/12/2026 10:53:45');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110284','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/12/2026 10:53:45');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110284','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/12/2026 10:53:45');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110285','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/14/2026 12:17:20');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110285','TOC','TL',4, 5, 4, 5, 4, 1, 5, 4, 4, 3, 1, 4,3.6667,0.7333,'4/14/2026 12:17:20');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110285','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/14/2026 12:17:20');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110287','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/13/2026 16:26:28');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110287','TOC','TL',5, 5, 5, 5, 4, 5, 5, 5, 5, 5, 5, 5,4.9167,0.9833,'4/13/2026 16:26:28');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110287','TOC','GAP',4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,4.0,0.8,'4/13/2026 16:26:28');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110289','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/18/2026 9:18:24');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110289','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/18/2026 9:18:24');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110289','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/18/2026 9:18:24');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110290','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/15/2026 15:10:14');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110290','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/15/2026 15:10:14');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110290','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/15/2026 15:10:14');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110291','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/12/2026 16:22:23');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110291','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/12/2026 16:22:23');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110291','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/12/2026 16:22:23');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110292','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/12/2026 8:44:56');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110292','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/12/2026 8:44:56');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110292','TOC','GAP',4, 4, 4, 4, 4, 4, 5, 5, 4, 4, 5, 4,4.25,0.85,'4/12/2026 8:44:56');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110293','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/13/2026 8:00:01');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110293','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/13/2026 8:00:01');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110293','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/13/2026 8:00:01');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110295','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/14/2026 9:28:31');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110295','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/14/2026 9:28:31');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110295','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/14/2026 9:28:31');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110296','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/14/2026 17:54:58');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110296','TOC','TL',4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,4.0,0.8,'4/14/2026 17:54:58');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110296','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/14/2026 17:54:58');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110297','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/15/2026 9:32:36');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110297','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/15/2026 9:32:36');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110297','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/15/2026 9:32:36');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110298','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/15/2026 17:59:03');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110298','TOC','TL',1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,1.0,0.2,'4/15/2026 17:59:03');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110298','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/15/2026 17:59:03');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110299','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/11/2026 23:15:32');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110299','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/11/2026 23:15:32');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110299','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/11/2026 23:15:32');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110300','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/12/2026 17:46:48');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110300','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/12/2026 17:46:48');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110300','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/12/2026 17:46:48');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110302','TOC','CO',1, 1, 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,1.0,0.3333,'4/13/2026 17:50:53');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110302','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/13/2026 17:50:53');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110302','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/13/2026 17:50:53');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110303','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/16/2026 9:36:41');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110303','TOC','TL',4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,4.0,0.8,'4/16/2026 9:36:41');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110303','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/16/2026 9:36:41');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110305','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/13/2026 12:13:15');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110305','TOC','TL',5, 4, 3, 4, 5, 4, 4, 5, 5, 5, 5, 4,4.4167,0.8833,'4/13/2026 12:13:15');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110305','TOC','GAP',5, 5, 5, 5, 5, 4, 5, 5, 5, 5, 5, 5,4.9167,0.9833,'4/13/2026 12:13:15');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110311','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/12/2026 13:32:34');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110311','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/12/2026 13:32:34');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110311','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/12/2026 13:32:34');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110312','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/13/2026 9:24:26');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110312','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/13/2026 9:24:26');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110312','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/13/2026 9:24:26');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110313','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/15/2026 13:45:49');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110313','TOC','TL',5, 4, 4, 4, 4, 4, 4, 4, 3, 5, 4, 4,4.0833,0.8167,'4/15/2026 13:45:49');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110313','TOC','GAP',4, 3, 4, 3, 3, 3, 5, 4, 5, 2, 5, 5,3.8333,0.7667,'4/15/2026 13:45:49');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110315','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/12/2026 9:19:21');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110315','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/12/2026 9:19:21');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110315','TOC','GAP',4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,4.0,0.8,'4/12/2026 9:19:21');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110318','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/14/2026 16:30:33');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110318','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/14/2026 16:30:33');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110318','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/14/2026 16:30:33');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110320','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/12/2026 19:11:12');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110320','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/12/2026 19:11:12');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110320','TOC','GAP',4, 4, 5, 4, 4, 4, 4, 4, 4, 4, 5, 5,4.25,0.85,'4/12/2026 19:11:12');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110321','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/15/2026 8:08:11');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110321','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/15/2026 8:08:11');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110321','TOC','GAP',4, 4, 4, 3, 3, 3, 3, 3, 4, 3, 2, 4,3.3333,0.6667,'4/15/2026 8:08:11');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110322','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/17/2026 14:29:35');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110322','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/17/2026 14:29:35');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110322','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/17/2026 14:29:35');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110325','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/14/2026 10:52:55');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110325','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/14/2026 10:52:55');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110325','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/14/2026 10:52:55');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110327','TOC','CO',3, 3, 2, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/16/2026 16:38:43');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110327','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/16/2026 16:38:43');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110327','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/16/2026 16:38:43');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110395','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/14/2026 8:04:06');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110395','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/14/2026 8:04:06');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110395','TOC','GAP',4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,4.0,0.8,'4/14/2026 8:04:06');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110462','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/11/2026 22:41:07');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110462','TOC','TL',4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,4.8333,0.9667,'4/11/2026 22:41:07');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110462','TOC','GAP',1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,1.0,0.2,'4/11/2026 22:41:07');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110581','TOC','CO',3, 3, 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.75,0.9167,'4/16/2026 8:12:16');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110581','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/16/2026 8:12:16');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110581','TOC','GAP',4, 4, 3, 4, 2, 3, 4, 5, 4, 2, 3, 5,3.5833,0.7167,'4/16/2026 8:12:16');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110701','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/16/2026 19:27:32');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110701','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/16/2026 19:27:32');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110701','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/16/2026 19:27:32');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110791','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/16/2026 18:03:08');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110791','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/16/2026 18:03:08');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('23110791','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/16/2026 18:03:08');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120021','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/12/2026 14:57:59');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120021','TOC','TL',4, 5, 5, 5, 4, 5, 5, 5, 5, 5, 5, 5,4.8333,0.9667,'4/12/2026 14:57:59');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120021','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/12/2026 14:57:59');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120025','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/14/2026 20:43:47');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120025','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/14/2026 20:43:47');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120025','TOC','GAP',5, 4, 5, 5, 5, 4, 5, 5, 5, 4, 5, 5,4.75,0.95,'4/14/2026 20:43:47');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120027','TOC','CO',2, 2, 2, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.0,0.6667,'4/16/2026 12:25:30');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120027','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/16/2026 12:25:30');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120027','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/16/2026 12:25:30');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120028','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/17/2026 15:53:59');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120028','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/17/2026 15:53:59');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120028','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/17/2026 15:53:59');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120029','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/17/2026 11:40:46');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120029','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/17/2026 11:40:46');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120029','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/17/2026 11:40:46');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120030','TOC','CO',3, 3, 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,3.0,1.0,'4/17/2026 13:05:10');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120030','TOC','TL',5, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,4.9167,0.9833,'4/17/2026 13:05:10');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120030','TOC','GAP',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/17/2026 13:05:10');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120031','TOC','CO',3, 3, 2, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,2.5,0.8333,'4/12/2026 20:35:37');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120031','TOC','TL',5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,5.0,1.0,'4/12/2026 20:35:37');
INSERT INTO feedback_raw (reg_no,subject_code,form_type,q1,q2,q3,q4,q5,q6,q7,q8,q9,q10,q11,q12,avg_score,norm_score,submitted_at) VALUES ('24120031','TOC','GAP',4, 3, 4, 4, 3, 3, 4, 3, 4, 5, 5, 5,3.9167,0.7833,'4/12/2026 20:35:37');

-- CO Attainment (pre-computed)
INSERT INTO co_attainment (subject_code,co_number,co_label,normalized_score,attainment_level) VALUES ('DVA',1,'CO1',0.8701,'High');
INSERT INTO co_attainment (subject_code,co_number,co_label,normalized_score,attainment_level) VALUES ('DVA',2,'CO2',0.8192,'High');
INSERT INTO co_attainment (subject_code,co_number,co_label,normalized_score,attainment_level) VALUES ('DVA',3,'CO3',0.9153,'High');
INSERT INTO co_attainment (subject_code,co_number,co_label,normalized_score,attainment_level) VALUES ('DVA',4,'CO4',0.8249,'High');
INSERT INTO co_attainment (subject_code,co_number,co_label,normalized_score,attainment_level) VALUES ('ML',1,'CO1',0.8927,'High');
INSERT INTO co_attainment (subject_code,co_number,co_label,normalized_score,attainment_level) VALUES ('ML',2,'CO2',0.8701,'High');
INSERT INTO co_attainment (subject_code,co_number,co_label,normalized_score,attainment_level) VALUES ('ML',3,'CO3',0.8644,'High');
INSERT INTO co_attainment (subject_code,co_number,co_label,normalized_score,attainment_level) VALUES ('ML',4,'CO4',0.887,'High');
INSERT INTO co_attainment (subject_code,co_number,co_label,normalized_score,attainment_level) VALUES ('SE',1,'CO1',0.9096,'High');
INSERT INTO co_attainment (subject_code,co_number,co_label,normalized_score,attainment_level) VALUES ('SE',2,'CO2',0.887,'High');
INSERT INTO co_attainment (subject_code,co_number,co_label,normalized_score,attainment_level) VALUES ('SE',3,'CO3',0.8588,'High');
INSERT INTO co_attainment (subject_code,co_number,co_label,normalized_score,attainment_level) VALUES ('SE',4,'CO4',0.8814,'High');
INSERT INTO co_attainment (subject_code,co_number,co_label,normalized_score,attainment_level) VALUES ('TOC',1,'CO1',0.9778,'High');
INSERT INTO co_attainment (subject_code,co_number,co_label,normalized_score,attainment_level) VALUES ('TOC',2,'CO2',0.9722,'High');
INSERT INTO co_attainment (subject_code,co_number,co_label,normalized_score,attainment_level) VALUES ('TOC',3,'CO3',0.9667,'High');
INSERT INTO co_attainment (subject_code,co_number,co_label,normalized_score,attainment_level) VALUES ('TOC',4,'CO4',0.95,'High');

-- ==================== VERIFY ====================
-- Run these after loading to confirm everything worked:
-- SELECT * FROM v_final_co_score;
-- SELECT * FROM v_subject_summary;
-- SELECT COUNT(*) FROM feedback_raw;
-- SELECT COUNT(*) FROM students;
