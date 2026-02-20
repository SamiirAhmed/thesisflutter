/*  MySQL 8+ (InnoDB, utf8mb4)
    - Part A: tables WITHOUT foreign keys (create first)
    - Part B: tables WITH foreign keys (create after)
    - All tables include created_at, updated_at
*/

SET NAMES utf8mb4;
SET time_zone = '+03:00';

140182

-- =========================
-- Part A) Tables WITHOUT FK
-- =========================

CREATE TABLE roles (
  role_id     INT AUTO_INCREMENT PRIMARY KEY,
  role_name   VARCHAR(50)  NOT NULL,
  description VARCHAR(255) NULL,
  status      VARCHAR(20)  NOT NULL DEFAULT 'Active',
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_roles_role_name (role_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE address (
  add_no     INT AUTO_INCREMENT PRIMARY KEY,
  district   VARCHAR(100) NOT NULL,
  villages   VARCHAR(100) NULL,
  area       VARCHAR(100) NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE parents (
  parent_no  INT AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(120) NOT NULL,
  tell1      VARCHAR(30)  NULL,
  tell2      VARCHAR(30)  NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE school (
  sch_no     INT AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(150) NOT NULL,
  addres     VARCHAR(255) NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_school_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE campuses (
  camp_no    INT AUTO_INCREMENT PRIMARY KEY,
  campus     VARCHAR(120) NOT NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_campuses_campus (campus)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE faculties (
  faculty_no INT AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(150) NOT NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_faculties_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE semesters (
  sem_no        INT AUTO_INCREMENT PRIMARY KEY,
  semister_name VARCHAR(50) NOT NULL,
  created_at    DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_semesters_name (semister_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE academics (
  acy_no      INT AUTO_INCREMENT PRIMARY KEY,
  start_date  DATE        NOT NULL,
  end_date    DATE        NOT NULL,
  active_year VARCHAR(30) NOT NULL,
  created_at  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_academics_active_year (active_year)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE jobs (
  job_no     INT AUTO_INCREMENT PRIMARY KEY,
  title      VARCHAR(120) NOT NULL,
  salary     DECIMAL(12,2) NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_jobs_title (title)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE decree (
  dec_no       INT AUTO_INCREMENT PRIMARY KEY,
  decree_name  VARCHAR(150) NOT NULL,
  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_decree_name (decree_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE subjects (
  sub_no     INT AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(150) NOT NULL,
  code       VARCHAR(50)  NOT NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_subjects_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE categories (
  cat_no     INT AUTO_INCREMENT PRIMARY KEY,
  cat_name   VARCHAR(80) NOT NULL,
  created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_categories_name (cat_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE Exams (
  ex_no     INT AUTO_INCREMENT PRIMARY KEY,
  Exam      VARCHAR(50) NOT NULL,
  created_at DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_exams_exam (Exam)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE allowed_exam_apeal_types (
  aeat_no   INT AUTO_INCREMENT PRIMARY KEY,
  Type      VARCHAR(60) NOT NULL,
  created_at DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_allowed_exam_appeal_types_type (Type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- =================================
-- Part B) Tables WITH foreign keys
-- =================================

CREATE TABLE departments (
  dept_no    INT AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(150) NOT NULL,
  faculty_no INT NOT NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_departments_name (name),
  KEY idx_departments_faculty_no (faculty_no),
  CONSTRAINT fk_departments_faculties
    FOREIGN KEY (faculty_no) REFERENCES faculties(faculty_no)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE classes (
  cls_no     INT AUTO_INCREMENT PRIMARY KEY,
  cl_name    VARCHAR(120) NOT NULL,
  dept_no    INT NOT NULL,
  camp_no    INT NOT NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_classes_cl_name (cl_name),
  KEY idx_classes_dept_no (dept_no),
  KEY idx_classes_camp_no (camp_no),
  CONSTRAINT fk_classes_departments
    FOREIGN KEY (dept_no) REFERENCES departments(dept_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_classes_campuses
    FOREIGN KEY (camp_no) REFERENCES campuses(camp_no)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE users (
  user_id       INT AUTO_INCREMENT PRIMARY KEY,
  role_id       INT NOT NULL,
  full_name     VARCHAR(150) NOT NULL,
  username      VARCHAR(80)  NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  phone         VARCHAR(30)  NULL,
  email         VARCHAR(150) NULL,
  status        VARCHAR(20)  NOT NULL DEFAULT 'Active',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_users_username (username),
  UNIQUE KEY uq_users_email (email),
  KEY idx_users_role_id (role_id),
  CONSTRAINT fk_users_roles
    FOREIGN KEY (role_id) REFERENCES roles(role_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE students (
  std_id        INT AUTO_INCREMENT PRIMARY KEY,
  user_id       INT NOT NULL,
  student_id    VARCHAR(50)  NOT NULL,
  name          VARCHAR(150) NOT NULL,
  tell          VARCHAR(30)  NULL,
  gender        VARCHAR(15)  NULL,
  email         VARCHAR(150) NULL,
  add_no        INT NULL,
  dob           DATE NULL,
  parent_no     INT NULL,
  register_date DATE NULL,
  mother        VARCHAR(150) NULL,
  sch_no        INT NULL,
  nira          VARCHAR(50)  NULL,
  status        VARCHAR(20)  NOT NULL DEFAULT 'Active',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_students_user_id (user_id),
  UNIQUE KEY uq_students_student_id (student_id),
  KEY idx_students_add_no (add_no),
  KEY idx_students_parent_no (parent_no),
  KEY idx_students_sch_no (sch_no),
  CONSTRAINT fk_students_users
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_students_address
    FOREIGN KEY (add_no) REFERENCES address(add_no)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_students_parents
    FOREIGN KEY (parent_no) REFERENCES parents(parent_no)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_students_school
    FOREIGN KEY (sch_no) REFERENCES school(sch_no)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE tearchers (
  teacher_no  INT AUTO_INCREMENT PRIMARY KEY,
  user_id     INT NOT NULL,
  teacher_id  VARCHAR(50)  NOT NULL,
  name        VARCHAR(150) NOT NULL,
  tell        VARCHAR(30)  NULL,
  email       VARCHAR(150) NULL,
  gender      VARCHAR(15)  NULL,
  hire_date   DATE NULL,
  job_no      INT NULL,
  dec_no      INT NULL,
  status      VARCHAR(20)  NOT NULL DEFAULT 'Active',
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_teachers_user_id (user_id),
  UNIQUE KEY uq_teachers_teacher_id (teacher_id),
  KEY idx_teachers_job_no (job_no),
  KEY idx_teachers_dec_no (dec_no),
  CONSTRAINT fk_teachers_users
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_teachers_jobs
    FOREIGN KEY (job_no) REFERENCES jobs(job_no)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_teachers_decree
    FOREIGN KEY (dec_no) REFERENCES decree(dec_no)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE studet_classes (
  sc_no     INT AUTO_INCREMENT PRIMARY KEY,
  cls_no    INT NOT NULL,
  std_id    INT NOT NULL,
  sem_no    INT NOT NULL,
  acy_no    INT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_student_classes_cls_no (cls_no),
  KEY idx_student_classes_std_id (std_id),
  KEY idx_student_classes_sem_no (sem_no),
  KEY idx_student_classes_acy_no (acy_no),
  CONSTRAINT fk_student_classes_classes
    FOREIGN KEY (cls_no) REFERENCES classes(cls_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_student_classes_students
    FOREIGN KEY (std_id) REFERENCES students(std_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_student_classes_semesters
    FOREIGN KEY (sem_no) REFERENCES semesters(sem_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_student_classes_academics
    FOREIGN KEY (acy_no) REFERENCES academics(acy_no)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE subject_class (
  sub_cl_no  INT AUTO_INCREMENT PRIMARY KEY,
  sub_no     INT NOT NULL,
  cls_no     INT NOT NULL,
  teacher_no INT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_subject_class_sub_no (sub_no),
  KEY idx_subject_class_cls_no (cls_no),
  KEY idx_subject_class_teacher_no (teacher_no),
  CONSTRAINT fk_subject_class_subjects
    FOREIGN KEY (sub_no) REFERENCES subjects(sub_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_subject_class_classes
    FOREIGN KEY (cls_no) REFERENCES classes(cls_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_subject_class_teachers
    FOREIGN KEY (teacher_no) REFERENCES tearchers(teacher_no)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Classroom Issues module
-- ----------------------------

CREATE TABLE class_issues (
  cl_issue_id INT AUTO_INCREMENT PRIMARY KEY,
  issue_name  VARCHAR(120) NOT NULL,
  cat_no      INT NOT NULL,
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_class_issues_cat_no (cat_no),
  CONSTRAINT fk_class_issues_categories
    FOREIGN KEY (cat_no) REFERENCES categories(cat_no)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE leaders (
  lead_id   INT AUTO_INCREMENT PRIMARY KEY,
  cls_no    INT NOT NULL,
  std_id    INT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_leaders_cls_no (cls_no),
  UNIQUE KEY uq_leaders_std_id (std_id),
  KEY idx_leaders_cls_no (cls_no),
  KEY idx_leaders_std_id (std_id),
  CONSTRAINT fk_leaders_classes
    FOREIGN KEY (cls_no) REFERENCES classes(cls_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_leaders_students
    FOREIGN KEY (std_id) REFERENCES students(std_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE class_issues_complaints (
  cl_is_co_no  INT AUTO_INCREMENT PRIMARY KEY,
  cl_issue_id  INT NOT NULL,
  description  TEXT NOT NULL,
  lead_id      INT NOT NULL,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_class_issues_complaints_issue (cl_issue_id),
  KEY idx_class_issues_complaints_lead (lead_id),
  CONSTRAINT fk_cic_issue
    FOREIGN KEY (cl_issue_id) REFERENCES class_issues(cl_issue_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_cic_leader
    FOREIGN KEY (lead_id) REFERENCES leaders(lead_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE class_issue_assign (
  cia_no            INT AUTO_INCREMENT PRIMARY KEY,
  cl_is_co_no       INT NOT NULL,
  assigned_to_user_id INT NOT NULL,
  assigned_date     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  assigned_status   VARCHAR(30) NOT NULL DEFAULT 'Pending',
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_class_issue_assign_complaint (cl_is_co_no),
  KEY idx_class_issue_assign_assigned_to (assigned_to_user_id),
  CONSTRAINT fk_cia_complaint
    FOREIGN KEY (cl_is_co_no) REFERENCES class_issues_complaints(cl_is_co_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_cia_users
    FOREIGN KEY (assigned_to_user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE class_issue_tracking (
  cit_no            INT AUTO_INCREMENT PRIMARY KEY,
  cl_is_co_no       INT NOT NULL,
  old_status        VARCHAR(30) NULL,
  new_status        VARCHAR(30) NOT NULL,
  changed_by_user_id INT NOT NULL,
  changed_date      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  note              VARCHAR(255) NULL,
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_cit_complaint (cl_is_co_no),
  KEY idx_cit_changed_by (changed_by_user_id),
  CONSTRAINT fk_cit_complaint
    FOREIGN KEY (cl_is_co_no) REFERENCES class_issues_complaints(cl_is_co_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_cit_users
    FOREIGN KEY (changed_by_user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Campus Environment module
-- ----------------------------

CREATE TABLE campus_enviroment (
  camp_env_no     INT AUTO_INCREMENT PRIMARY KEY,
  campuses_issues VARCHAR(120) NOT NULL,
  cat_no          INT NOT NULL,
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_campus_env_cat_no (cat_no),
  CONSTRAINT fk_campus_env_categories
    FOREIGN KEY (cat_no) REFERENCES categories(cat_no)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE campus_envo_complaints (
  cmp_env_com_no INT AUTO_INCREMENT PRIMARY KEY,
  camp_env_no    INT NOT NULL,
  images         TEXT NULL,
  description    TEXT NOT NULL,
  std_id         INT NOT NULL,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_cec_camp_env_no (camp_env_no),
  KEY idx_cec_std_id (std_id),
  CONSTRAINT fk_cec_env
    FOREIGN KEY (camp_env_no) REFERENCES campus_enviroment(camp_env_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_cec_student
    FOREIGN KEY (std_id) REFERENCES students(std_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE campus_env_assign (
  cea_no            INT AUTO_INCREMENT PRIMARY KEY,
  cmp_env_com_no    INT NOT NULL,
  assigned_to_user_id INT NOT NULL,
  assigned_date     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  assigned_status   VARCHAR(30) NOT NULL DEFAULT 'Pending',
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_cea_complaint (cmp_env_com_no),
  KEY idx_cea_assigned_to (assigned_to_user_id),
  CONSTRAINT fk_cea_complaint
    FOREIGN KEY (cmp_env_com_no) REFERENCES campus_envo_complaints(cmp_env_com_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_cea_users
    FOREIGN KEY (assigned_to_user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE campus_env_tracking (
  cet_no            INT AUTO_INCREMENT PRIMARY KEY,
  cmp_env_com_no    INT NOT NULL,
  old_status        VARCHAR(30) NULL,
  new_status        VARCHAR(30) NOT NULL,
  changed_by_user_id INT NOT NULL,
  changed_date      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  note              VARCHAR(255) NULL,
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_cet_complaint (cmp_env_com_no),
  KEY idx_cet_changed_by (changed_by_user_id),
  CONSTRAINT fk_cet_complaint
    FOREIGN KEY (cmp_env_com_no) REFERENCES campus_envo_complaints(cmp_env_com_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_cet_users
    FOREIGN KEY (changed_by_user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE campus_env_support (
  ces_no         INT AUTO_INCREMENT PRIMARY KEY,
  cmp_env_com_no INT NOT NULL,
  std_id         INT NOT NULL,
  supported_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_campus_env_support_once (cmp_env_com_no, std_id),
  KEY idx_ces_complaint (cmp_env_com_no),
  KEY idx_ces_std_id (std_id),
  CONSTRAINT fk_ces_complaint
    FOREIGN KEY (cmp_env_com_no) REFERENCES campus_envo_complaints(cmp_env_com_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_ces_student
    FOREIGN KEY (std_id) REFERENCES students(std_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Exams & Exam Appeals module
-- ----------------------------

CREATE TABLE Exam_register (
  er_no     INT AUTO_INCREMENT PRIMARY KEY,
  ex_no     INT NOT NULL,
  sem_no    INT NOT NULL,
  acy_no    INT NOT NULL,
  max_mark  INT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_er_ex_no (ex_no),
  KEY idx_er_sem_no (sem_no),
  KEY idx_er_acy_no (acy_no),
  CONSTRAINT fk_er_exams
    FOREIGN KEY (ex_no) REFERENCES Exams(ex_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_er_semesters
    FOREIGN KEY (sem_no) REFERENCES semesters(sem_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_er_academics
    FOREIGN KEY (acy_no) REFERENCES academics(acy_no)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE appeal_types (
  at_no    INT AUTO_INCREMENT PRIMARY KEY,
  er_no    INT NOT NULL,
  aeat_no  INT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_at_er_no (er_no),
  KEY idx_at_aeat_no (aeat_no),
  CONSTRAINT fk_at_exam_register
    FOREIGN KEY (er_no) REFERENCES Exam_register(er_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_at_allowed_types
    FOREIGN KEY (aeat_no) REFERENCES allowed_exam_apeal_types(aeat_no)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE allow_apeals (
  aa_no      INT AUTO_INCREMENT PRIMARY KEY,
  HOE_no     INT NOT NULL,
  er_no      INT NOT NULL,
  start_date DATETIME NOT NULL,
  end_date   DATETIME NOT NULL,
  status     VARCHAR(30) NOT NULL DEFAULT 'Open',
  allow      TINYINT(1)  NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_aa_hoe (HOE_no),
  KEY idx_aa_er_no (er_no),
  CONSTRAINT fk_allow_appeals_hoe_user
    FOREIGN KEY (HOE_no) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_allow_appeals_exam_register
    FOREIGN KEY (er_no) REFERENCES Exam_register(er_no)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE exam_appeals (
  ea_no      INT AUTO_INCREMENT PRIMARY KEY,
  sc_no      INT NOT NULL,
  aa_no      INT NOT NULL,
  at_no      INT NOT NULL,
  appeal_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status     VARCHAR(30) NOT NULL DEFAULT 'Submitted',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_ea_sc_no (sc_no),
  KEY idx_ea_aa_no (aa_no),
  KEY idx_ea_at_no (at_no),
  CONSTRAINT fk_ea_student_classes
    FOREIGN KEY (sc_no) REFERENCES studet_classes(sc_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_ea_allow_appeals
    FOREIGN KEY (aa_no) REFERENCES allow_apeals(aa_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_ea_appeal_types
    FOREIGN KEY (at_no) REFERENCES appeal_types(at_no)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE exam_appeal_subjects (
  eas_no         INT AUTO_INCREMENT PRIMARY KEY,
  ea_no          INT NOT NULL,
  sub_cl_no      INT NOT NULL,
  reason         TEXT NOT NULL,
  reference_no   VARCHAR(80) NULL,
  requested_mark INT NULL,
  current_mark   INT NULL,
  status         VARCHAR(30) NOT NULL DEFAULT 'Submitted',
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_eas_ea_no (ea_no),
  KEY idx_eas_sub_cl_no (sub_cl_no),
  CONSTRAINT fk_eas_exam_appeals
    FOREIGN KEY (ea_no) REFERENCES exam_appeals(ea_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_eas_subject_class
    FOREIGN KEY (sub_cl_no) REFERENCES subject_class(sub_cl_no)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE exam_appeal_assign (
  assign_no          INT AUTO_INCREMENT PRIMARY KEY,
  eas_no             INT NOT NULL,
  assigned_to_user_id INT NOT NULL,
  assigned_date      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  assigned_status    VARCHAR(30) NOT NULL DEFAULT 'Pending',
  created_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_eaa_eas_no (eas_no),
  KEY idx_eaa_assigned_to (assigned_to_user_id),
  CONSTRAINT fk_eaa_subject
    FOREIGN KEY (eas_no) REFERENCES exam_appeal_subjects(eas_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_eaa_user
    FOREIGN KEY (assigned_to_user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE exam_appeal_tracking (
  track_no     INT AUTO_INCREMENT PRIMARY KEY,
  eas_no       INT NOT NULL,
  old_status   VARCHAR(30) NULL,
  new_status   VARCHAR(30) NOT NULL,
  changed_by   INT NOT NULL,
  changed_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  note         VARCHAR(255) NULL,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_eat_eas_no (eas_no),
  KEY idx_eat_changed_by (changed_by),
  CONSTRAINT fk_eat_subject
    FOREIGN KEY (eas_no) REFERENCES exam_appeal_subjects(eas_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_eat_user
    FOREIGN KEY (changed_by) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE coursework_deadlines (
  cwd_no        INT AUTO_INCREMENT PRIMARY KEY,
  aa_no         INT NOT NULL,
  deadline_date DATETIME NOT NULL,
  note          VARCHAR(255) NULL,
  set_by_user_id INT NOT NULL,
  set_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status        VARCHAR(20) NOT NULL DEFAULT 'Active',
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_coursework_deadlines_aa_no (aa_no),
  KEY idx_cwd_set_by (set_by_user_id),
  CONSTRAINT fk_cwd_allow_appeals
    FOREIGN KEY (aa_no) REFERENCES allow_apeals(aa_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_cwd_user
    FOREIGN KEY (set_by_user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE exam_officer_tasks (
  eot_no            INT AUTO_INCREMENT PRIMARY KEY,
  aa_no             INT NOT NULL,
  assigned_to_user_id INT NOT NULL,
  target_dept_no    INT NULL,
  target_cls_no     INT NULL,
  target_sem_no     INT NULL,
  target_acy_no     INT NULL,
  task_title        VARCHAR(150) NOT NULL,
  task_description  TEXT NULL,
  deadline_date     DATETIME NULL,
  created_by_user_id INT NOT NULL,
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  status            VARCHAR(20) NOT NULL DEFAULT 'Open',
  KEY idx_eot_aa_no (aa_no),
  KEY idx_eot_assigned_to (assigned_to_user_id),
  KEY idx_eot_target_dept_no (target_dept_no),
  KEY idx_eot_target_cls_no (target_cls_no),
  KEY idx_eot_target_sem_no (target_sem_no),
  KEY idx_eot_target_acy_no (target_acy_no),
  KEY idx_eot_created_by (created_by_user_id),
  CONSTRAINT fk_eot_allow_appeals
    FOREIGN KEY (aa_no) REFERENCES allow_apeals(aa_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_eot_assigned_to_user
    FOREIGN KEY (assigned_to_user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_eot_target_dept
    FOREIGN KEY (target_dept_no) REFERENCES departments(dept_no)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_eot_target_class
    FOREIGN KEY (target_cls_no) REFERENCES classes(cls_no)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_eot_target_sem
    FOREIGN KEY (target_sem_no) REFERENCES semesters(sem_no)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_eot_target_acy
    FOREIGN KEY (target_acy_no) REFERENCES academics(acy_no)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_eot_created_by_user
    FOREIGN KEY (created_by_user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Notifications & Messaging
-- ----------------------------

CREATE TABLE notifications (
  not_no           INT AUTO_INCREMENT PRIMARY KEY,
  receiver_user_id INT NOT NULL,
  title            VARCHAR(150) NOT NULL,
  message          TEXT NOT NULL,
  module           VARCHAR(50) NOT NULL,
  record_id        INT NULL,
  is_read          TINYINT(1) NOT NULL DEFAULT 0,
  created_at       DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  read_at          DATETIME   NULL,
  status           VARCHAR(20) NOT NULL DEFAULT 'Active',
  updated_at       DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_notifications_receiver (receiver_user_id),
  KEY idx_notifications_module (module),
  CONSTRAINT fk_notifications_users
    FOREIGN KEY (receiver_user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE messages (
  msg_no        INT AUTO_INCREMENT PRIMARY KEY,
  sender_user_id INT NOT NULL,
  title         VARCHAR(150) NOT NULL,
  body          TEXT NOT NULL,
  channel_app   TINYINT(1) NOT NULL DEFAULT 1,
  channel_sms   TINYINT(1) NOT NULL DEFAULT 0,
  module        VARCHAR(50) NOT NULL,
  created_date  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status        VARCHAR(20) NOT NULL DEFAULT 'Active',
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_messages_sender (sender_user_id),
  KEY idx_messages_module (module),
  CONSTRAINT fk_messages_users
    FOREIGN KEY (sender_user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE message_recipients (
  mr_no          INT AUTO_INCREMENT PRIMARY KEY,
  msg_no         INT NOT NULL,
  receiver_user_id INT NOT NULL,
  phone_number   VARCHAR(30) NULL,
  app_status     VARCHAR(20) NOT NULL DEFAULT 'Queued',
  sms_status     VARCHAR(20) NOT NULL DEFAULT 'NotSent',
  sent_date      DATETIME NULL,
  delivered_date DATETIME NULL,
  fail_reason    VARCHAR(255) NULL,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_message_recipients_once (msg_no, receiver_user_id),
  KEY idx_mr_msg_no (msg_no),
  KEY idx_mr_receiver (receiver_user_id),
  CONSTRAINT fk_mr_messages
    FOREIGN KEY (msg_no) REFERENCES messages(msg_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_mr_users
    FOREIGN KEY (receiver_user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE message_groups (
  mg_no            INT AUTO_INCREMENT PRIMARY KEY,
  group_name       VARCHAR(150) NOT NULL,
  created_by_user_id INT NOT NULL,
  created_date     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status           VARCHAR(20) NOT NULL DEFAULT 'Active',
  created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_message_groups_name (group_name),
  KEY idx_mg_created_by (created_by_user_id),
  CONSTRAINT fk_mg_users
    FOREIGN KEY (created_by_user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE message_group_members (
  mgm_no    INT AUTO_INCREMENT PRIMARY KEY,
  mg_no     INT NOT NULL,
  user_id   INT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_mgm_once (mg_no, user_id),
  KEY idx_mgm_mg_no (mg_no),
  KEY idx_mgm_user_id (user_id),
  CONSTRAINT fk_mgm_groups
    FOREIGN KEY (mg_no) REFERENCES message_groups(mg_no)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_mgm_users
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- 1) Yahye Ali Isse
CALL sp_create_teacher(
  'Yahye Ali Isse','0617100001','yahye@example.com','Male','2024-01-10','Active','WEB',
  @u1,@tno1,@tid1,@pass1
);
SELECT @tid1 AS username_teacher_id, @pass1 AS generated_password;

-- 2) Ismail M Jamaal
CALL sp_create_teacher(
  'Ismail M Jamaal','0617100002','ismail@example.com','Male','2024-02-15','Active','WEB',
  @u2,@tno2,@tid2,@pass2
);
SELECT @tid2 AS username_teacher_id, @pass2 AS generated_password;

-- 3) Abdifitah Gabeyre
CALL sp_create_teacher(
  'Abdifitah Gabeyre','0617100003','abdifitah@example.com','Male','2024-03-20','Active','WEB',
  @u3,@tno3,@tid3,@pass3
);
SELECT @tid3 AS username_teacher_id, @pass3 AS generated_password;


CALL sp_create_student(
  'Mohamed Mukhtar',
  '0615000001',
  'Male',
  'mohamed@example.com',
  NULL,
  '2004-03-10',
  1,              -- parent_no
  CURDATE(),
  'Amina',
  1,              -- sch_no
  'NIRA-001',
  'Active',
  'APP',
  @u1, @s1, @sid1, @pass1
);

SELECT @sid1 AS username, @pass1 AS password;

CALL sp_create_student(
  'Maida Hashi',
  '0615000002',
  'Female',
  'maida@example.com',
  NULL,
  '2005-07-21',
  2,
  CURDATE(),
  'Sahra',
  1,
  'NIRA-002',
  'Active',
  'APP',
  @u2, @s2, @sid2, @pass2
);

SELECT @sid2 AS username, @pass2 AS password;


CALL sp_create_student(
  'Haliima Nour',
  '0615000003',
  'Female',
  'haliima@example.com',
  NULL,
  '2004-11-02',
  3,
  CURDATE(),
  'Maryan',
  1,
  'NIRA-003',
  'Active',
  'APP',
  @u3, @s3, @sid3, @pass3
);

SELECT @sid3 AS username, @pass3 AS password;


CALL sp_create_student(
  'Samiir Ahmed',
  '0615000004',
  'Male',
  'samiir@example.com',
  NULL,
  '2003-09-15',
  4,
  CURDATE(),
  'Hodan',
  1,
  'NIRA-004',
  'Active',
  'APP',
  @u4, @s4, @sid4, @pass4
);

SELECT @sid4 AS username, @pass4 AS password;

