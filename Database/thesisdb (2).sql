-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Feb 24, 2026 at 11:57 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `thesisdb`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_role_dashboard` (IN `p_role_id` INT)   BEGIN
    SELECT 'main_dashboard' as `key`, 'Main Dashboard' as title, '/dashboard' as route;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_role_modules` (IN `p_role_id` INT)   BEGIN
    IF p_role_id = 2 THEN
        -- Teacher Modules
        SELECT 'course_appeal' as `key`, 'Course Appeal' as title, '/appeals' as route, 'Manage student appeals' as sub_title, 'assignment_turned_in' as icon_name
        UNION ALL
        SELECT 'coursework_notifications' as `key`, 'Coursework Notifications' as title, '/notifications' as route, 'Recent notifications' as sub_title, 'notifications_active' as icon_name
        UNION ALL
        SELECT 'report' as `key`, 'Reports' as title, '/reports' as route, 'View performance' as sub_title, 'bar_chart' as icon_name;
    ELSE
        -- Updated Student Modules
        SELECT 'exam_appeal' as `key`, 'Exam Appeal' as title, '/exam_appeal' as route, 'Submit and track exam appeals' as sub_title, 'assignment_turned_in_rounded' as icon_name
        UNION ALL
        SELECT 'class_issue' as `key`, 'Class Issue' as title, '/class_issue' as route, 'Report classroom concerns' as sub_title, 'class_rounded' as icon_name
        UNION ALL
        SELECT 'campus_env' as `key`, 'Campus Environment' as title, '/campus_env' as route, 'General facilities issues' as sub_title, 'apartment_rounded' as icon_name;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_role_permissions` (IN `p_role_id` INT)   BEGIN
    SELECT 'appeals.view' as permission_key;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `login_proc` (IN `p_identifier` VARCHAR(50), IN `p_pin` VARCHAR(255))   BEGIN
    SELECT * FROM users 
    WHERE (username = p_identifier OR CAST(user_id AS CHAR) = p_identifier)
    LIMIT 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_get_class_reports` (IN `p_user_id` BIGINT)   BEGIN
    DECLARE v_role_id INT;
    SELECT role_id INTO v_role_id FROM users WHERE id = p_user_id;

    IF v_role_id = 6 THEN
        -- Ardaygu wuxuu arkayaa kaliya dhibka uu isagu soo gudbiyey
        SELECT r.id, i.issue_name as issue_type, r.description, r.status, r.resolution_note, r.created_at, u.full_name as reporter_name
        FROM class_reports r
        JOIN class_issues i ON r.cl_issue_id = i.cl_issue_id
        JOIN users u ON r.reported_by = u.id
        WHERE r.reported_by = p_user_id
        ORDER BY r.created_at DESC;
    ELSE
        -- Macallinka ama Faculty-ga waxay arkayaan dhammaan
        SELECT r.id, i.issue_name as issue_type, r.description, r.status, r.resolution_note, r.created_at, u.full_name as reporter_name
        FROM class_reports r
        JOIN class_issues i ON r.cl_issue_id = i.cl_issue_id
        JOIN users u ON r.reported_by = u.id
        ORDER BY r.created_at DESC;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_get_issue_categories` ()   BEGIN
    SELECT cl_issue_id, issue_name FROM class_issues;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_update_report_status` (IN `p_report_id` BIGINT, IN `p_user_id` BIGINT, IN `p_status` VARCHAR(50), IN `p_note` TEXT)   BEGIN
    DECLARE v_old_status VARCHAR(50);
    SELECT status INTO v_old_status FROM class_reports WHERE id = p_report_id;
    
    -- Bedel status-ka table-ka rasmiga ah
    UPDATE class_reports 
    SET status = p_status, 
        resolution_note = CASE WHEN p_status IN ('Resolved', 'Rejected') THEN p_note ELSE resolution_note END,
        updated_at = NOW()
    WHERE id = p_report_id;
    
    -- Ku dar log-ga (History)
    INSERT INTO class_report_logs (class_report_id, user_id, old_status, new_status, note, created_at)
    VALUES (p_report_id, p_user_id, v_old_status, p_status, p_note, NOW());
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_create_student` (IN `p_name` VARCHAR(150), IN `p_tell` VARCHAR(30), IN `p_gender` VARCHAR(15), IN `p_email` VARCHAR(150), IN `p_add_no` INT, IN `p_dob` DATE, IN `p_parent_no` INT, IN `p_register_date` DATE, IN `p_mother` VARCHAR(150), IN `p_sch_no` INT, IN `p_nira` VARCHAR(50), IN `p_status` VARCHAR(20), IN `p_access_channel` ENUM('APP','WEB','BOTH',''), OUT `o_user_id` INT, OUT `o_std_id` INT, OUT `o_student_id` VARCHAR(20), OUT `o_plain_password` VARCHAR(6))   BEGIN
  DECLARE v_student_id VARCHAR(20);
  DECLARE v_pass_plain VARCHAR(6);
  DECLARE v_pass_hash  VARCHAR(255);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'sp_create_student failed. Transaction rolled back.';
  END;

  -- 1) generate student_id like STU280002
  CALL sp_generate_student_id(NULL, v_student_id);

  -- 2) generate 6-digit random password (keeps leading zeros)
  SET v_pass_plain = LPAD(FLOOR(RAND() * 1000000), 6, '0');

  -- 3) hash password (SHA-256). If you want bcrypt, hash in Laravel instead.
  SET v_pass_hash = SHA2(v_pass_plain, 256);

  START TRANSACTION;

  -- 4) insert into users (role_id=1 student, username=student_id)
  -- if p_access_channel is NULL, rely on table default by not overriding it
  IF p_access_channel IS NULL THEN
    INSERT INTO users(
      role_id, username, password_hash, status, created_at, updated_at
    )
    VALUES (
      1,
      v_student_id,
      v_pass_hash,
      COALESCE(p_status, 'Active'),
      CURRENT_TIMESTAMP,
      CURRENT_TIMESTAMP
    );
  ELSE
    INSERT INTO users(
      role_id, username, password_hash, status, Accees_channel, created_at, updated_at
    )
    VALUES (
      1,
      v_student_id,
      v_pass_hash,
      COALESCE(p_status, 'Active'),
      p_access_channel,
      CURRENT_TIMESTAMP,
      CURRENT_TIMESTAMP
    );
  END IF;

  SET o_user_id = LAST_INSERT_ID();

  -- 5) insert into students (matches your table)
  INSERT INTO students(
    user_id, student_id, name, tell, gender, email, add_no, dob, parent_no,
    register_date, mother, sch_no, nira, status, created_at, updated_at
  )
  VALUES (
    o_user_id,
    v_student_id,
    p_name,
    p_tell,
    p_gender,
    p_email,
    p_add_no,
    p_dob,
    p_parent_no,
    p_register_date,
    p_mother,
    p_sch_no,
    p_nira,
    COALESCE(p_status, 'Active'),
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
  );

  SET o_std_id = LAST_INSERT_ID();
INSERT INTO student_initial_credentials (std_id, user_id, username, plain_password)
VALUES (o_std_id, o_user_id, v_student_id, v_pass_plain);



  COMMIT;

  -- outputs
  SET o_student_id = v_student_id;
  SET o_plain_password = v_pass_plain;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_create_teacher` (IN `p_name` VARCHAR(150), IN `p_tell` VARCHAR(30), IN `p_email` VARCHAR(150), IN `p_gender` VARCHAR(15), IN `p_hire_date` DATE, IN `p_status` VARCHAR(20), IN `p_access_channel` ENUM('APP','WEB','BOTH',''), OUT `o_user_id` INT, OUT `o_teacher_no` INT, OUT `o_teacher_id` VARCHAR(20), OUT `o_plain_password` VARCHAR(6))   BEGIN
  DECLARE v_teacher_id  VARCHAR(20);
  DECLARE v_pass_plain  VARCHAR(6);
  DECLARE v_pass_hash   VARCHAR(255);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'sp_create_teacher failed. Transaction rolled back.';
  END;

  CALL sp_generate_teacher_id(NULL, v_teacher_id);

  SET v_pass_plain = LPAD(FLOOR(RAND() * 1000000), 6, '0');
  SET v_pass_hash  = SHA2(v_pass_plain, 256);

  START TRANSACTION;

  IF p_access_channel IS NULL THEN
    INSERT INTO users(role_id, username, password_hash, status, created_at, updated_at)
    VALUES (2, v_teacher_id, v_pass_hash, COALESCE(p_status,'Active'), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
  ELSE
    INSERT INTO users(role_id, username, password_hash, status, Accees_channel, created_at, updated_at)
    VALUES (2, v_teacher_id, v_pass_hash, COALESCE(p_status,'Active'), p_access_channel, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
  END IF;

  SET o_user_id = LAST_INSERT_ID();

  INSERT INTO teachers(
    user_id, teacher_id, name, tell, email, gender, hire_date, status, created_at, updated_at
  )
  VALUES (
    o_user_id, v_teacher_id, p_name, p_tell, p_email, p_gender, p_hire_date,
    COALESCE(p_status,'Active'), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
  );

  SET o_teacher_no = LAST_INSERT_ID();

  INSERT INTO teacher_initial_credentials(teacher_no, user_id, username, plain_password)
  VALUES (o_teacher_no, o_user_id, v_teacher_id, v_pass_plain);

  COMMIT;

  SET o_teacher_id = v_teacher_id;
  SET o_plain_password = v_pass_plain;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_generate_student_id` (IN `p_year` INT, OUT `p_student_id` VARCHAR(20))   BEGIN
  DECLARE v_year2 CHAR(2);
  DECLARE v_last  INT;

  SET v_year2 = LPAD(RIGHT(COALESCE(p_year, YEAR(CURDATE())), 2), 2, '0');

  START TRANSACTION;

  SELECT year2, last_no
    INTO @cur_year2, v_last
  FROM id_sequences_year
  WHERE seq_key = 'STU'
  FOR UPDATE;

  IF @cur_year2 IS NULL THEN
    INSERT INTO id_sequences_year(seq_key, year2, last_no)
    VALUES ('STU', v_year2, 0);
    SET @cur_year2 = v_year2;
    SET v_last = 0;
  END IF;

  IF @cur_year2 <> v_year2 THEN
    UPDATE id_sequences_year
      SET year2 = v_year2,
          last_no = 1
    WHERE seq_key = 'STU';
    SET v_last = 1;
  ELSE
    UPDATE id_sequences_year
      SET last_no = last_no + 1
    WHERE seq_key = 'STU';
    SET v_last = v_last + 1;
  END IF;

  COMMIT;

  SET p_student_id = fn_format_id('STU', v_year2, v_last);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_generate_teacher_id` (IN `p_year` INT, OUT `p_teacher_id` VARCHAR(20))   BEGIN
  DECLARE v_year2 CHAR(2);
  DECLARE v_last  INT;

  SET v_year2 = LPAD(RIGHT(COALESCE(p_year, YEAR(CURDATE())), 2), 2, '0');

  START TRANSACTION;

  SELECT year2, last_no
    INTO @cur_year2_t, v_last
  FROM id_sequences_year
  WHERE seq_key = 'TCH'
  FOR UPDATE;

  IF @cur_year2_t IS NULL THEN
    INSERT INTO id_sequences_year(seq_key, year2, last_no)
    VALUES ('TCH', v_year2, 0);
    SET @cur_year2_t = v_year2;
    SET v_last = 0;
  END IF;

  IF @cur_year2_t <> v_year2 THEN
    UPDATE id_sequences_year
      SET year2 = v_year2,
          last_no = 1
    WHERE seq_key = 'TCH';
    SET v_last = 1;
  ELSE
    UPDATE id_sequences_year
      SET last_no = last_no + 1
    WHERE seq_key = 'TCH';
    SET v_last = v_last + 1;
  END IF;

  COMMIT;

  SET p_teacher_id = fn_format_id('TCH', v_year2, v_last);
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_format_id` (`p_prefix` VARCHAR(10), `p_year2` CHAR(2), `p_no` INT) RETURNS VARCHAR(20) CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
  RETURN CONCAT(p_prefix, p_year2, LPAD(p_no, 4, '0'));
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `academics`
--

CREATE TABLE `academics` (
  `acy_no` int(11) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `active_year` varchar(30) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `academics`
--

INSERT INTO `academics` (`acy_no`, `start_date`, `end_date`, `active_year`, `created_at`, `updated_at`) VALUES
(1, '2026-02-01', '2026-06-30', '2025-2026', '2026-02-18 08:47:08', '2026-02-18 08:47:08');

-- --------------------------------------------------------

--
-- Table structure for table `address`
--

CREATE TABLE `address` (
  `add_no` int(11) NOT NULL,
  `district` varchar(100) NOT NULL,
  `villages` varchar(100) DEFAULT NULL,
  `area` varchar(100) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `address`
--

INSERT INTO `address` (`add_no`, `district`, `villages`, `area`, `created_at`, `updated_at`) VALUES
(1, 'Karaan', 'Fagax', 'Majidka Turkiga', '2026-02-18 08:47:40', '2026-02-18 08:47:40'),
(2, 'Deyniile ', 'Raadelka', 'School Niil', '2026-02-18 08:48:31', '2026-02-18 08:48:31'),
(3, 'Hodan', 'Digfeer', 'bishacas', '2026-02-18 08:48:31', '2026-02-18 08:48:31'),
(4, 'Grasbaleey', 'Weedow', 'Hormuud', '2026-02-18 08:48:50', '2026-02-18 08:48:50');

-- --------------------------------------------------------

--
-- Table structure for table `allowed_exam_apeal_types`
--

CREATE TABLE `allowed_exam_apeal_types` (
  `aeat_no` int(11) NOT NULL,
  `Type` varchar(60) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `allow_apeals`
--

CREATE TABLE `allow_apeals` (
  `aa_no` int(11) NOT NULL,
  `HOE_no` int(11) NOT NULL,
  `er_no` int(11) NOT NULL,
  `start_date` datetime NOT NULL,
  `end_date` datetime NOT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'Open',
  `allow` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `appeal_types`
--

CREATE TABLE `appeal_types` (
  `at_no` int(11) NOT NULL,
  `er_no` int(11) NOT NULL,
  `aeat_no` int(11) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `campuses`
--

CREATE TABLE `campuses` (
  `camp_no` int(11) NOT NULL,
  `campus` varchar(120) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `campuses`
--

INSERT INTO `campuses` (`camp_no`, `campus`, `created_at`, `updated_at`) VALUES
(1, 'Campus 1', '2026-02-18 08:49:16', '2026-02-18 08:49:16'),
(2, 'Campus 3\r\n', '2026-02-18 08:49:25', '2026-02-18 08:49:25'),
(3, 'Campus 3', '2026-02-18 08:53:10', '2026-02-18 08:53:10');

-- --------------------------------------------------------

--
-- Table structure for table `campus_enviroment`
--

CREATE TABLE `campus_enviroment` (
  `camp_env_no` int(11) NOT NULL,
  `campuses_issues` varchar(120) NOT NULL,
  `cat_no` int(11) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `campus_envo_complaints`
--

CREATE TABLE `campus_envo_complaints` (
  `cmp_env_com_no` int(11) NOT NULL,
  `camp_env_no` int(11) NOT NULL,
  `images` text DEFAULT NULL,
  `description` text NOT NULL,
  `std_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `campus_env_assign`
--

CREATE TABLE `campus_env_assign` (
  `cea_no` int(11) NOT NULL,
  `cmp_env_com_no` int(11) NOT NULL,
  `assigned_to_user_id` int(11) NOT NULL,
  `assigned_date` datetime NOT NULL DEFAULT current_timestamp(),
  `assigned_status` varchar(30) NOT NULL DEFAULT 'Pending',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `campus_env_support`
--

CREATE TABLE `campus_env_support` (
  `ces_no` int(11) NOT NULL,
  `cmp_env_com_no` int(11) NOT NULL,
  `std_id` int(11) NOT NULL,
  `supported_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `campus_env_tracking`
--

CREATE TABLE `campus_env_tracking` (
  `cet_no` int(11) NOT NULL,
  `cmp_env_com_no` int(11) NOT NULL,
  `old_status` varchar(30) DEFAULT NULL,
  `new_status` varchar(30) NOT NULL,
  `changed_by_user_id` int(11) NOT NULL,
  `changed_date` datetime NOT NULL DEFAULT current_timestamp(),
  `note` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `cat_no` int(11) NOT NULL,
  `cat_name` varchar(80) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`cat_no`, `cat_name`, `created_at`, `updated_at`) VALUES
(1, 'Exam Appeal', '2026-02-24 00:30:52', '2026-02-24 00:30:52'),
(2, 'Class Issue', '2026-02-24 00:30:52', '2026-02-24 00:30:52'),
(3, 'Campus enviroment', '2026-02-24 00:30:52', '2026-02-24 00:43:17');

-- --------------------------------------------------------

--
-- Table structure for table `classes`
--

CREATE TABLE `classes` (
  `cls_no` int(11) NOT NULL,
  `cl_name` varchar(120) NOT NULL,
  `dept_no` int(11) NOT NULL,
  `camp_no` int(11) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `classes`
--

INSERT INTO `classes` (`cls_no`, `cl_name`, `dept_no`, `camp_no`, `created_at`, `updated_at`) VALUES
(1, 'CA221', 3, 1, '2026-02-18 08:54:14', '2026-02-18 08:54:14'),
(2, 'CA222', 3, 2, '2026-02-18 08:54:14', '2026-02-18 08:54:14'),
(3, 'CA223', 3, 2, '2026-02-18 08:54:26', '2026-02-18 08:54:26'),
(4, 'CA224', 3, 2, '2026-02-18 08:54:38', '2026-02-18 08:54:38');

-- --------------------------------------------------------

--
-- Table structure for table `class_issues`
--

CREATE TABLE `class_issues` (
  `cl_issue_id` int(11) NOT NULL,
  `issue_name` varchar(120) NOT NULL,
  `cat_no` int(11) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `class_issues`
--

INSERT INTO `class_issues` (`cl_issue_id`, `issue_name`, `cat_no`, `created_at`, `updated_at`) VALUES
(1, 'Projector', 2, '2026-02-24 00:47:41', '2026-02-24 00:47:41'),
(2, 'Tables', 2, '2026-02-24 00:47:41', '2026-02-24 00:47:41'),
(3, 'Doors', 2, '2026-02-24 01:10:21', '2026-02-24 01:10:21');

-- --------------------------------------------------------

--
-- Table structure for table `class_issues_complaints`
--

CREATE TABLE `class_issues_complaints` (
  `cl_is_co_no` int(11) NOT NULL,
  `cl_issue_id` int(11) NOT NULL,
  `description` text NOT NULL,
  `lead_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `class_issues_complaints`
--

INSERT INTO `class_issues_complaints` (`cl_is_co_no`, `cl_issue_id`, `description`, `lead_id`, `created_at`, `updated_at`) VALUES
(1, 1, 'projectorka cilada ka jirto daciif wye', 1, '2026-02-24 09:08:58', '2026-02-24 09:08:58'),
(2, 2, 'misas ka jajab ka jira', 2, '2026-02-24 09:11:23', '2026-02-24 09:11:23'),
(3, 3, 'daqada we jabsan tahay', 1, '2026-02-24 09:52:45', '2026-02-24 09:52:45'),
(4, 3, 'broken', 1, '2026-02-24 10:54:38', '2026-02-24 10:54:38');

-- --------------------------------------------------------

--
-- Table structure for table `class_issue_assign`
--

CREATE TABLE `class_issue_assign` (
  `cia_no` int(11) NOT NULL,
  `cl_is_co_no` int(11) NOT NULL,
  `assigned_to_user_id` int(11) NOT NULL,
  `assigned_date` datetime NOT NULL DEFAULT current_timestamp(),
  `assigned_status` varchar(30) NOT NULL DEFAULT 'Pending',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `class_issue_tracking`
--

CREATE TABLE `class_issue_tracking` (
  `cit_no` int(11) NOT NULL,
  `cl_is_co_no` int(11) NOT NULL,
  `old_status` varchar(33) DEFAULT NULL,
  `new_status` enum('pending','Resolved','Reject') NOT NULL DEFAULT 'pending',
  `changed_by_user_id` int(11) NOT NULL,
  `changed_date` datetime NOT NULL DEFAULT current_timestamp(),
  `note` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `class_issue_tracking`
--

INSERT INTO `class_issue_tracking` (`cit_no`, `cl_is_co_no`, `old_status`, `new_status`, `changed_by_user_id`, `changed_date`, `note`, `created_at`, `updated_at`) VALUES
(1, 1, NULL, 'Resolved', 29, '2026-02-24 01:08:58', 'Submitted', '2026-02-24 09:08:58', '2026-02-24 01:09:55'),
(2, 2, NULL, 'pending', 30, '2026-02-24 01:11:23', 'Submitted', '2026-02-24 09:11:23', '2026-02-24 09:11:23'),
(3, 3, NULL, 'pending', 29, '2026-02-24 01:52:45', 'Submitted', '2026-02-24 09:52:45', '2026-02-24 09:52:45'),
(4, 4, NULL, 'pending', 29, '2026-02-24 02:54:38', 'Submitted', '2026-02-24 10:54:38', '2026-02-24 10:54:38');

-- --------------------------------------------------------

--
-- Table structure for table `coursework_deadlines`
--

CREATE TABLE `coursework_deadlines` (
  `cwd_no` int(11) NOT NULL,
  `aa_no` int(11) NOT NULL,
  `deadline_date` datetime NOT NULL,
  `note` varchar(255) DEFAULT NULL,
  `set_by_user_id` int(11) NOT NULL,
  `set_at` datetime NOT NULL DEFAULT current_timestamp(),
  `status` varchar(20) NOT NULL DEFAULT 'Active',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `departments`
--

CREATE TABLE `departments` (
  `dept_no` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `faculty_no` int(11) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `departments`
--

INSERT INTO `departments` (`dept_no`, `name`, `faculty_no`, `created_at`, `updated_at`) VALUES
(1, 'Computer Science', 1, '2026-02-18 09:51:25', '2026-02-18 09:51:25'),
(3, 'Computer Application', 1, '2026-02-18 08:51:49', '2026-02-18 08:51:49'),
(4, 'Network $ Security', 1, '2026-02-18 08:51:49', '2026-02-18 08:51:49'),
(5, 'Multimedia', 1, '2026-02-18 08:52:05', '2026-02-18 08:52:05');

-- --------------------------------------------------------

--
-- Table structure for table `exams`
--

CREATE TABLE `exams` (
  `ex_no` int(11) NOT NULL,
  `Exam` varchar(50) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `exam_appeals`
--

CREATE TABLE `exam_appeals` (
  `ea_no` int(11) NOT NULL,
  `sc_no` int(11) NOT NULL,
  `aa_no` int(11) NOT NULL,
  `at_no` int(11) NOT NULL,
  `appeal_date` datetime NOT NULL DEFAULT current_timestamp(),
  `status` varchar(30) NOT NULL DEFAULT 'Submitted',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `exam_appeal_assign`
--

CREATE TABLE `exam_appeal_assign` (
  `assign_no` int(11) NOT NULL,
  `eas_no` int(11) NOT NULL,
  `assigned_to_user_id` int(11) NOT NULL,
  `assigned_date` datetime NOT NULL DEFAULT current_timestamp(),
  `assigned_status` varchar(30) NOT NULL DEFAULT 'Pending',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `exam_appeal_subjects`
--

CREATE TABLE `exam_appeal_subjects` (
  `eas_no` int(11) NOT NULL,
  `ea_no` int(11) NOT NULL,
  `sub_cl_no` int(11) NOT NULL,
  `reason` text NOT NULL,
  `reference_no` varchar(80) DEFAULT NULL,
  `requested_mark` int(11) DEFAULT NULL,
  `current_mark` int(11) DEFAULT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'Submitted',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `exam_appeal_tracking`
--

CREATE TABLE `exam_appeal_tracking` (
  `track_no` int(11) NOT NULL,
  `eas_no` int(11) NOT NULL,
  `old_status` varchar(30) DEFAULT NULL,
  `new_status` varchar(30) NOT NULL,
  `changed_by` int(11) NOT NULL,
  `changed_date` datetime NOT NULL DEFAULT current_timestamp(),
  `note` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `exam_officer_tasks`
--

CREATE TABLE `exam_officer_tasks` (
  `eot_no` int(11) NOT NULL,
  `aa_no` int(11) NOT NULL,
  `assigned_to_user_id` int(11) NOT NULL,
  `target_dept_no` int(11) DEFAULT NULL,
  `target_cls_no` int(11) DEFAULT NULL,
  `target_sem_no` int(11) DEFAULT NULL,
  `target_acy_no` int(11) DEFAULT NULL,
  `task_title` varchar(150) NOT NULL,
  `task_description` text DEFAULT NULL,
  `deadline_date` datetime DEFAULT NULL,
  `created_by_user_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `status` varchar(20) NOT NULL DEFAULT 'Open'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `exam_register`
--

CREATE TABLE `exam_register` (
  `er_no` int(11) NOT NULL,
  `ex_no` int(11) NOT NULL,
  `sem_no` int(11) NOT NULL,
  `acy_no` int(11) NOT NULL,
  `max_mark` int(11) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `faculties`
--

CREATE TABLE `faculties` (
  `faculty_no` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `faculties`
--

INSERT INTO `faculties` (`faculty_no`, `name`, `created_at`, `updated_at`) VALUES
(1, 'Computer & IT', '2026-02-18 08:50:20', '2026-02-18 08:50:20'),
(2, 'Ecocomic', '2026-02-18 08:50:20', '2026-02-18 08:50:20'),
(3, 'Engineering', '2026-02-18 08:50:31', '2026-02-18 08:50:31');

-- --------------------------------------------------------

--
-- Table structure for table `id_sequences_year`
--

CREATE TABLE `id_sequences_year` (
  `seq_key` varchar(10) NOT NULL,
  `year2` char(2) NOT NULL,
  `last_no` int(11) NOT NULL DEFAULT 0,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `id_sequences_year`
--

INSERT INTO `id_sequences_year` (`seq_key`, `year2`, `last_no`, `updated_at`) VALUES
('STU', '26', 4, '2026-02-18 14:19:39'),
('TCH', '26', 5, '2026-02-19 09:33:19');

-- --------------------------------------------------------

--
-- Table structure for table `leaders`
--

CREATE TABLE `leaders` (
  `lead_id` int(11) NOT NULL,
  `cls_no` int(11) NOT NULL,
  `std_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `leaders`
--

INSERT INTO `leaders` (`lead_id`, `cls_no`, `std_id`, `created_at`, `updated_at`) VALUES
(1, 1, 1, '2026-02-22 23:20:40', '2026-02-22 23:20:40'),
(2, 2, 2, '2026-02-23 10:04:17', '2026-02-23 10:04:17');

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `msg_no` int(11) NOT NULL,
  `sender_user_id` int(11) NOT NULL,
  `title` varchar(150) NOT NULL,
  `body` text NOT NULL,
  `channel_app` tinyint(1) NOT NULL DEFAULT 1,
  `channel_sms` tinyint(1) NOT NULL DEFAULT 0,
  `module` varchar(50) NOT NULL,
  `created_date` datetime NOT NULL DEFAULT current_timestamp(),
  `status` varchar(20) NOT NULL DEFAULT 'Active',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `message_groups`
--

CREATE TABLE `message_groups` (
  `mg_no` int(11) NOT NULL,
  `group_name` varchar(150) NOT NULL,
  `created_by_user_id` int(11) NOT NULL,
  `created_date` datetime NOT NULL DEFAULT current_timestamp(),
  `status` varchar(20) NOT NULL DEFAULT 'Active',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `message_group_members`
--

CREATE TABLE `message_group_members` (
  `mgm_no` int(11) NOT NULL,
  `mg_no` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `message_recipients`
--

CREATE TABLE `message_recipients` (
  `mr_no` int(11) NOT NULL,
  `msg_no` int(11) NOT NULL,
  `receiver_user_id` int(11) NOT NULL,
  `phone_number` varchar(30) DEFAULT NULL,
  `app_status` varchar(20) NOT NULL DEFAULT 'Queued',
  `sms_status` varchar(20) NOT NULL DEFAULT 'NotSent',
  `sent_date` datetime DEFAULT NULL,
  `delivered_date` datetime DEFAULT NULL,
  `fail_reason` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `not_no` int(11) NOT NULL,
  `receiver_user_id` int(11) NOT NULL,
  `title` varchar(150) NOT NULL,
  `message` text NOT NULL,
  `module` varchar(50) NOT NULL,
  `record_id` int(11) DEFAULT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `read_at` datetime DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'Active',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `parents`
--

CREATE TABLE `parents` (
  `parent_no` int(11) NOT NULL,
  `name` varchar(120) NOT NULL,
  `tell1` varchar(30) DEFAULT NULL,
  `tell2` varchar(30) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `parents`
--

INSERT INTO `parents` (`parent_no`, `name`, `tell1`, `tell2`, `created_at`, `updated_at`) VALUES
(1, 'Mukhtar Muhudiin', '615869874', '615643744', '2026-02-18 08:57:58', '2026-02-18 08:57:58'),
(2, 'Hashi Addani', '615634763', '617247488', '2026-02-18 08:57:58', '2026-02-18 08:57:58'),
(3, 'Nur Ibrahim', '615567348', '613894675', '2026-02-18 08:58:47', '2026-02-18 08:58:47'),
(4, 'Ahmed Wehliye', '615634799', '61674958', '2026-02-18 08:58:47', '2026-02-18 08:58:47');

-- --------------------------------------------------------

--
-- Table structure for table `personal_access_tokens`
--

CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) UNSIGNED NOT NULL,
  `name` text NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `personal_access_tokens`
--

INSERT INTO `personal_access_tokens` (`id`, `tokenable_type`, `tokenable_id`, `name`, `token`, `abilities`, `last_used_at`, `expires_at`, `created_at`, `updated_at`) VALUES
(18, 'App\\Models\\User', 30, 'APP', 'c95b52f8b514fcfada3e43fad7edc74f6432955b9b093d8ec8c638136475cdc0', '[\"appeals.view\"]', '2026-02-24 17:11:23', NULL, '2026-02-24 17:11:06', '2026-02-24 17:11:23'),
(25, 'App\\Models\\User', 31, 'APP', '55b6a0722c0117dc5fc45ef548436f9b535fe3e5b446c6f2e7970c7f84e62551', '[\"appeals.view\"]', '2026-02-24 18:53:06', NULL, '2026-02-24 18:53:06', '2026-02-24 18:53:06'),
(26, 'App\\Models\\User', 29, 'APP', '1bf35d7796529f09b9a9f13b288654946cfec9c63e1d50255f7476915eb9491c', '[\"appeals.view\"]', '2026-02-24 18:54:39', NULL, '2026-02-24 18:54:02', '2026-02-24 18:54:39'),
(27, 'App\\Models\\User', 32, 'APP', 'f7f69c76026aae60b501886ba4e2d23462dfe48974cb17d5c1036d59fd0ae17f', '[\"appeals.view\"]', '2026-02-24 18:55:26', NULL, '2026-02-24 18:55:02', '2026-02-24 18:55:26');

-- --------------------------------------------------------

--
-- Table structure for table `roles`
--

CREATE TABLE `roles` (
  `role_id` int(11) NOT NULL,
  `role_name` varchar(50) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'Active',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `roles`
--

INSERT INTO `roles` (`role_id`, `role_name`, `description`, `status`, `created_at`, `updated_at`) VALUES
(1, 'Student', 'University Student', 'Active', '2026-02-18 14:16:46', '2026-02-20 00:16:02'),
(2, 'Teacher', 'University Teacher', 'Active', '2026-02-18 14:16:46', '2026-02-20 00:16:02'),
(3, 'HeadOfExam', 'Head Of Exam Department', 'Active', '2026-02-18 14:16:46', '2026-02-18 14:16:46'),
(4, 'Faculty', 'Faculty Office User', 'Active', '2026-02-18 14:16:46', '2026-02-18 14:16:46');

-- --------------------------------------------------------

--
-- Table structure for table `school`
--

CREATE TABLE `school` (
  `sch_no` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `addres` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `school`
--

INSERT INTO `school` (`sch_no`, `name`, `addres`, `created_at`, `updated_at`) VALUES
(1, 'Jaabir Bin Hayyan', 'Yaqshid', '2026-02-18 08:59:35', '2026-02-18 08:59:35'),
(2, 'Niil school', 'deyniile', '2026-02-18 08:59:35', '2026-02-18 08:59:35'),
(3, 'SYL school', 'hodan', '2026-02-18 09:00:35', '2026-02-18 09:00:35'),
(4, 'mocaasir', 'waaberi', '2026-02-18 09:00:35', '2026-02-18 09:00:35');

-- --------------------------------------------------------

--
-- Table structure for table `semesters`
--

CREATE TABLE `semesters` (
  `sem_no` int(11) NOT NULL,
  `semister_name` varchar(50) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `semesters`
--

INSERT INTO `semesters` (`sem_no`, `semister_name`, `created_at`, `updated_at`) VALUES
(1, 'Semister 1', '2026-02-18 09:02:26', '2026-02-18 09:02:26'),
(2, 'Semister 2', '2026-02-18 09:02:26', '2026-02-18 09:02:26'),
(3, 'Semister 3', '2026-02-18 09:02:26', '2026-02-18 09:02:26'),
(4, 'Semister 4', '2026-02-18 09:02:26', '2026-02-18 09:02:26'),
(5, 'Semister 5', '2026-02-18 09:02:26', '2026-02-18 09:02:26'),
(6, 'Semister 6', '2026-02-18 09:02:26', '2026-02-18 09:02:26'),
(7, 'Semister 7', '2026-02-18 09:02:26', '2026-02-18 09:02:26'),
(8, 'Semister 8', '2026-02-18 09:02:26', '2026-02-18 09:02:26');

-- --------------------------------------------------------

--
-- Table structure for table `shifts`
--

CREATE TABLE `shifts` (
  `shift_no` int(11) NOT NULL,
  `shiftName` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `shifts`
--

INSERT INTO `shifts` (`shift_no`, `shiftName`) VALUES
(1, 'FullTime'),
(2, 'PartTime');

-- --------------------------------------------------------

--
-- Table structure for table `students`
--

CREATE TABLE `students` (
  `std_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `student_id` varchar(50) NOT NULL,
  `name` varchar(150) NOT NULL,
  `tell` varchar(30) DEFAULT NULL,
  `gender` varchar(15) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `add_no` int(11) DEFAULT NULL,
  `dob` date DEFAULT NULL,
  `parent_no` int(11) DEFAULT NULL,
  `register_date` date DEFAULT NULL,
  `mother` varchar(150) DEFAULT NULL,
  `sch_no` int(11) DEFAULT NULL,
  `nira` varchar(50) DEFAULT NULL,
  `status` enum('Active','InActive') NOT NULL DEFAULT 'Active',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `shift_no` int(11) DEFAULT NULL,
  `pob` varchar(100) DEFAULT 'Muqdisho',
  `grad_year` varchar(10) DEFAULT '2022',
  `grade` varchar(10) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `students`
--

INSERT INTO `students` (`std_id`, `user_id`, `student_id`, `name`, `tell`, `gender`, `email`, `add_no`, `dob`, `parent_no`, `register_date`, `mother`, `sch_no`, `nira`, `status`, `created_at`, `updated_at`, `shift_no`, `pob`, `grad_year`, `grade`) VALUES
(1, 29, 'STU260001', 'Mohamed Mukhtar', '0615000001', 'Male', 'mohamed@example.com', 1, '2004-03-10', 1, '2026-02-18', 'Istahil Shire Ali', 1, 'NIRA-001', 'Active', '2026-02-18 14:19:39', '2026-02-21 11:37:55', 1, 'Muqdisho', '2022', 'A'),
(2, 30, 'STU260002', 'Maida Hashi', '0615000002', 'Male', 'maida@example.com', 2, '2005-07-21', 2, '2026-02-18', 'Istahil Shire Ali', 2, 'NIRA-002', 'Active', '2026-02-18 14:19:39', '2026-02-21 11:37:55', 1, 'Muqdisho', '2022', 'B'),
(3, 31, 'STU260003', 'Haliima Nour', '0615000003', 'Male', 'haliima@example.com', 3, '2004-11-02', 3, '2026-02-18', 'Istahil Shire Ali', 3, 'NIRA-003', 'Active', '2026-02-18 14:19:39', '2026-02-21 11:37:55', 1, 'Muqdisho', '2022', 'C'),
(4, 32, 'STU260004', 'Samiir Ahmed', '0615000004', 'Male', 'samiir@example.com', 1, '2003-09-15', 4, '2026-02-18', 'Istahil Shire Ali', 4, 'NIRA-004', 'InActive', '2026-02-18 14:19:39', '2026-02-21 11:37:55', 2, 'Muqdisho', '2022', 'A-'),
(7, 16, 'STU260005', 'Abdihafid Ahmed Weheliye', '0610365557', 'Male', 'student@university.edu', 1, NULL, 1, NULL, 'Istahil Shire Ali', 1, 'NIRA-005', 'Active', '2026-02-20 09:34:38', '2026-02-21 11:34:42', 2, 'Muqdisho', '2022', 'A+');

-- --------------------------------------------------------

--
-- Table structure for table `student_initial_credentials`
--

CREATE TABLE `student_initial_credentials` (
  `cred_no` int(11) NOT NULL,
  `std_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `username` varchar(80) NOT NULL,
  `plain_password` varchar(6) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `delivered` tinyint(1) NOT NULL DEFAULT 0,
  `delivered_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `student_initial_credentials`
--

INSERT INTO `student_initial_credentials` (`cred_no`, `std_id`, `user_id`, `username`, `plain_password`, `created_at`, `delivered`, `delivered_at`) VALUES
(1, 1, 7, 'STU260001', '689901', '2026-02-18 14:19:39', 0, NULL),
(2, 2, 8, 'STU260002', '569600', '2026-02-18 14:19:39', 0, NULL),
(3, 3, 9, 'STU260003', '778299', '2026-02-18 14:19:39', 0, NULL),
(4, 4, 10, 'STU260004', '182693', '2026-02-18 14:19:39', 0, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `studet_classes`
--

CREATE TABLE `studet_classes` (
  `sc_no` int(11) NOT NULL,
  `cls_no` int(11) NOT NULL,
  `std_id` int(11) NOT NULL,
  `sem_no` int(11) NOT NULL,
  `acy_no` int(11) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `studet_classes`
--

INSERT INTO `studet_classes` (`sc_no`, `cls_no`, `std_id`, `sem_no`, `acy_no`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 1, 1, '2026-02-22 09:48:04', '2026-02-22 09:48:04'),
(2, 2, 2, 1, 1, '2026-02-22 09:48:04', '2026-02-22 09:48:04'),
(3, 1, 3, 1, 1, '2026-02-22 09:48:04', '2026-02-22 09:48:04'),
(4, 2, 4, 1, 1, '2026-02-22 09:48:04', '2026-02-22 09:48:04'),
(5, 1, 1, 1, 1, '2026-02-23 09:14:04', '2026-02-23 09:14:04');

-- --------------------------------------------------------

--
-- Table structure for table `subjects`
--

CREATE TABLE `subjects` (
  `sub_no` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `code` varchar(50) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `subjects`
--

INSERT INTO `subjects` (`sub_no`, `name`, `code`, `created_at`, `updated_at`) VALUES
(1, 'Introduction to Programming', 'CS101', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(2, 'Programming Fundamentals', 'CS102', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(3, 'Object Oriented Programming', 'CS103', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(4, 'Data Structures', 'CS201', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(5, 'Algorithms', 'CS202', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(6, 'Database Systems', 'CS203', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(7, 'SQL and Database Design', 'CS204', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(8, 'Web Development I', 'CS205', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(9, 'Web Development II', 'CS206', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(10, 'Mobile App Development', 'CS207', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(11, 'Software Engineering', 'CS208', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(12, 'System Analysis and Design', 'CS209', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(13, 'Computer Networks', 'CS210', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(14, 'Operating Systems', 'CS211', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(15, 'Computer Architecture', 'CS212', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(16, 'Cyber Security Basics', 'CS213', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(17, 'Artificial Intelligence', 'CS301', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(18, 'Machine Learning Basics', 'CS302', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(19, 'Cloud Computing Fundamentals', 'CS303', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(20, 'Version Control with Git', 'CS304', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(21, 'Arabic Language I', 'AR101', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(22, 'Arabic Language II', 'AR102', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(23, 'English Language I', 'EN101', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(24, 'English Language II', 'EN102', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(25, 'Tarbiyo and Ethics', 'TB101', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(26, 'Islamic Studies I', 'IS101', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(27, 'Islamic Studies II', 'IS102', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(28, 'Communication Skills', 'CSK101', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(29, 'Civic Education', 'CE101', '2026-02-21 09:08:31', '2026-02-21 09:08:31'),
(30, 'Somali Language', 'SO101', '2026-02-21 09:08:31', '2026-02-21 09:08:31');

-- --------------------------------------------------------

--
-- Table structure for table `subject_class`
--

CREATE TABLE `subject_class` (
  `sub_cl_no` int(11) NOT NULL,
  `sub_no` int(11) NOT NULL,
  `cls_no` int(11) NOT NULL,
  `teacher_no` int(11) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `subject_class`
--

INSERT INTO `subject_class` (`sub_cl_no`, `sub_no`, `cls_no`, `teacher_no`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 1, '2026-02-22 09:42:55', '2026-02-22 09:42:55'),
(2, 4, 1, 2, '2026-02-22 09:42:55', '2026-02-22 09:42:55'),
(3, 14, 1, 3, '2026-02-22 09:42:55', '2026-02-22 09:42:55'),
(4, 10, 1, 4, '2026-02-22 09:42:55', '2026-02-22 09:42:55'),
(5, 27, 1, 5, '2026-02-22 09:42:55', '2026-02-22 09:42:55'),
(6, 16, 1, 6, '2026-02-22 09:42:55', '2026-02-22 09:42:55'),
(7, 5, 2, 1, '2026-02-22 09:44:59', '2026-02-22 09:44:59'),
(8, 23, 2, 2, '2026-02-22 09:44:59', '2026-02-22 09:44:59'),
(9, 17, 2, 3, '2026-02-22 09:44:59', '2026-02-22 09:44:59'),
(10, 13, 2, 5, '2026-02-22 09:44:59', '2026-02-22 09:44:59'),
(11, 19, 2, 6, '2026-02-22 09:44:59', '2026-02-22 09:44:59'),
(12, 10, 2, 9, '2026-02-22 09:44:59', '2026-02-22 09:44:59');

-- --------------------------------------------------------

--
-- Table structure for table `teachers`
--

CREATE TABLE `teachers` (
  `teacher_no` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `teacher_id` varchar(50) NOT NULL,
  `name` varchar(150) NOT NULL,
  `tell` varchar(30) DEFAULT NULL,
  `specialization` varchar(100) DEFAULT NULL,
  `dept_no` int(11) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `gender` varchar(15) DEFAULT NULL,
  `hire_date` date DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'Active',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `teachers`
--

INSERT INTO `teachers` (`teacher_no`, `user_id`, `teacher_id`, `name`, `tell`, `specialization`, `dept_no`, `email`, `gender`, `hire_date`, `status`, `created_at`, `updated_at`) VALUES
(1, 1, 'TCH260001', 'Ahmed Ali Hassan', '06120000001', 'Computer Science', 1, 'tech001@university.edu', 'Male', '2020-01-01', 'Active', '2026-02-21 09:36:20', '2026-02-21 10:24:57'),
(2, 2, 'TCH260002', 'Maryan Abdullahi', '06120000002', 'Computer Science', 1, 'tech002@university.edu', 'Female', '2020-01-01', 'Active', '2026-02-21 09:36:20', '2026-02-21 10:24:57'),
(3, 3, 'TCH260003', 'Mohamed Nur', '06120000003', 'Computer Science', 1, 'tech003@university.edu', 'Male', '2020-01-01', 'Active', '2026-02-21 09:36:20', '2026-02-21 10:24:57'),
(4, 4, 'TCH260004', 'Hodan Farah', '06120000004', 'Computer Science', 1, 'tech004@university.edu', 'Female', '2020-01-01', 'Active', '2026-02-21 09:36:20', '2026-02-21 10:24:57'),
(5, 5, 'TCH260005', 'Abdirahman Yusuf', '06120000005', 'Computer Science', 1, 'tech005@university.edu', 'Male', '2020-01-01', 'Active', '2026-02-21 09:36:20', '2026-02-21 10:24:57'),
(6, 6, 'TCH260006', 'Asha Mohamed', '06120000006', 'Computer Science', 1, 'tech006@university.edu', 'Female', '2020-01-01', 'Active', '2026-02-21 09:36:20', '2026-02-21 10:24:57'),
(7, 7, 'TCH260007', 'Ismail Ahmed', '06120000007', 'Computer Science', 1, 'tech007@university.edu', 'Male', '2020-01-01', 'Active', '2026-02-21 09:36:20', '2026-02-21 10:24:57'),
(8, 8, 'TCH260008', 'Sahra Osman', '06120000008', 'Computer Science', 1, 'tech008@university.edu', 'Female', '2020-01-01', 'Active', '2026-02-21 09:36:20', '2026-02-21 10:24:57'),
(9, 9, 'TCH260009', 'Ali Ibrahim', '06120000009', 'Computer Science', 1, 'tech009@university.edu', 'Male', '2020-01-01', 'Active', '2026-02-21 09:36:20', '2026-02-21 10:24:57'),
(10, 10, 'TCH260010', 'Fadumo Hassan', '06120000010', 'Computer Science', 1, 'tech010@university.edu', 'Female', '2020-01-01', 'Active', '2026-02-21 09:36:20', '2026-02-21 10:24:57'),
(11, 11, 'TCH260011', 'Omar Abdi', '06120000011', 'Computer Science', 1, 'tech011@university.edu', 'Male', '2020-01-01', 'Active', '2026-02-21 09:36:20', '2026-02-21 10:24:57'),
(12, 12, 'TCH260012', 'Naima Yusuf', '06120000012', 'Computer Science', 1, 'tech012@university.edu', 'Female', '2020-01-01', 'Active', '2026-02-21 09:36:20', '2026-02-21 10:24:57');

-- --------------------------------------------------------

--
-- Table structure for table `teacher_initial_credentials`
--

CREATE TABLE `teacher_initial_credentials` (
  `cred_no` int(11) NOT NULL,
  `teacher_no` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `username` varchar(80) NOT NULL,
  `plain_password` varchar(6) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `delivered` tinyint(1) NOT NULL DEFAULT 0,
  `delivered_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `teacher_initial_credentials`
--

INSERT INTO `teacher_initial_credentials` (`cred_no`, `teacher_no`, `user_id`, `username`, `plain_password`, `created_at`, `delivered`, `delivered_at`) VALUES
(1, 3, 3, 'Tech003', '660845', '2026-02-18 14:19:27', 0, NULL),
(2, 4, 4, 'Tech004', '998168', '2026-02-18 14:19:27', 0, NULL),
(3, 5, 5, 'Tech005', '008306', '2026-02-18 14:19:27', 0, NULL),
(4, 6, 6, 'Tech006', '047025', '2026-02-19 09:33:19', 0, NULL),
(5, 7, 7, 'Tech007', '210209', '2026-02-19 09:33:19', 0, NULL),
(10, 1, 1, 'Tech001', '949750', '2026-02-21 10:18:34', 0, NULL),
(11, 2, 2, 'Tech002', '102019', '2026-02-21 10:18:34', 0, NULL),
(12, 8, 8, 'Tech008', '909971', '2026-02-21 10:18:34', 0, NULL),
(13, 9, 9, 'Tech009', '919227', '2026-02-21 10:18:34', 0, NULL),
(14, 10, 10, 'Tech010', '866225', '2026-02-21 10:18:34', 0, NULL),
(15, 11, 11, 'Tech011', '573443', '2026-02-21 10:18:34', 0, NULL),
(16, 12, 12, 'Tech012', '268540', '2026-02-21 10:18:34', 0, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `role_id` int(11) NOT NULL,
  `username` varchar(80) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `status` enum('Active','InActive') NOT NULL DEFAULT 'Active',
  `Accees_channel` enum('APP','WEB','BOTH','') NOT NULL DEFAULT 'APP',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `role_id`, `username`, `password_hash`, `status`, `Accees_channel`, `created_at`, `updated_at`) VALUES
(1, 2, 'TCH260001', '834386', 'Active', 'BOTH', '2026-02-21 11:05:19', '2026-02-21 11:43:13'),
(2, 2, 'TCH260002', '509726', 'Active', 'BOTH', '2026-02-21 11:14:29', '2026-02-21 11:43:13'),
(3, 2, 'TCH260003', '110176', 'Active', 'BOTH', '2026-02-21 11:14:29', '2026-02-21 11:43:13'),
(4, 2, 'TCH260004', '515004', 'Active', 'BOTH', '2026-02-21 11:14:29', '2026-02-21 11:43:13'),
(5, 2, 'TCH260005', '552608', 'Active', 'BOTH', '2026-02-21 11:14:29', '2026-02-21 11:43:13'),
(6, 2, 'TCH260006', '655768', 'Active', 'BOTH', '2026-02-21 11:14:29', '2026-02-21 11:43:13'),
(7, 2, 'TCH260007', '925535', 'Active', 'BOTH', '2026-02-21 11:14:29', '2026-02-21 11:43:13'),
(8, 2, 'TCH260008', '230242', 'Active', 'BOTH', '2026-02-21 11:14:29', '2026-02-21 11:43:13'),
(9, 2, 'TCH260009', '162113', 'Active', 'BOTH', '2026-02-21 11:14:29', '2026-02-21 11:43:13'),
(10, 2, 'TCH260010', '459437', 'Active', 'BOTH', '2026-02-21 11:14:29', '2026-02-21 11:43:13'),
(11, 2, 'TCH260011', '974651', 'Active', 'BOTH', '2026-02-21 11:14:29', '2026-02-21 11:43:13'),
(12, 2, 'TCH260012', '156021', 'Active', 'BOTH', '2026-02-21 11:14:29', '2026-02-21 11:43:13'),
(16, 1, 'STU260005', '128837', 'Active', 'APP', '2026-02-21 11:14:29', '2026-02-21 11:43:13'),
(29, 1, 'STU260001', '302110', 'Active', 'APP', '2026-02-21 11:37:55', '2026-02-21 11:43:13'),
(30, 1, 'STU260002', '842566', 'Active', 'APP', '2026-02-21 11:37:55', '2026-02-21 11:43:13'),
(31, 1, 'STU260003', '308590', 'Active', 'APP', '2026-02-21 11:37:55', '2026-02-21 11:43:13'),
(32, 1, 'STU260004', '412392', 'Active', 'APP', '2026-02-21 11:37:55', '2026-02-21 11:43:13');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `academics`
--
ALTER TABLE `academics`
  ADD PRIMARY KEY (`acy_no`),
  ADD UNIQUE KEY `uq_academics_active_year` (`active_year`);

--
-- Indexes for table `address`
--
ALTER TABLE `address`
  ADD PRIMARY KEY (`add_no`);

--
-- Indexes for table `allowed_exam_apeal_types`
--
ALTER TABLE `allowed_exam_apeal_types`
  ADD PRIMARY KEY (`aeat_no`),
  ADD UNIQUE KEY `uq_allowed_exam_appeal_types_type` (`Type`);

--
-- Indexes for table `allow_apeals`
--
ALTER TABLE `allow_apeals`
  ADD PRIMARY KEY (`aa_no`),
  ADD KEY `idx_aa_hoe` (`HOE_no`),
  ADD KEY `idx_aa_er_no` (`er_no`);

--
-- Indexes for table `appeal_types`
--
ALTER TABLE `appeal_types`
  ADD PRIMARY KEY (`at_no`),
  ADD KEY `idx_at_er_no` (`er_no`),
  ADD KEY `idx_at_aeat_no` (`aeat_no`);

--
-- Indexes for table `campuses`
--
ALTER TABLE `campuses`
  ADD PRIMARY KEY (`camp_no`),
  ADD UNIQUE KEY `uq_campuses_campus` (`campus`);

--
-- Indexes for table `campus_enviroment`
--
ALTER TABLE `campus_enviroment`
  ADD PRIMARY KEY (`camp_env_no`),
  ADD KEY `idx_campus_env_cat_no` (`cat_no`);

--
-- Indexes for table `campus_envo_complaints`
--
ALTER TABLE `campus_envo_complaints`
  ADD PRIMARY KEY (`cmp_env_com_no`),
  ADD KEY `idx_cec_camp_env_no` (`camp_env_no`),
  ADD KEY `idx_cec_std_id` (`std_id`);

--
-- Indexes for table `campus_env_assign`
--
ALTER TABLE `campus_env_assign`
  ADD PRIMARY KEY (`cea_no`),
  ADD KEY `idx_cea_complaint` (`cmp_env_com_no`),
  ADD KEY `idx_cea_assigned_to` (`assigned_to_user_id`);

--
-- Indexes for table `campus_env_support`
--
ALTER TABLE `campus_env_support`
  ADD PRIMARY KEY (`ces_no`),
  ADD UNIQUE KEY `uq_campus_env_support_once` (`cmp_env_com_no`,`std_id`),
  ADD KEY `idx_ces_complaint` (`cmp_env_com_no`),
  ADD KEY `idx_ces_std_id` (`std_id`);

--
-- Indexes for table `campus_env_tracking`
--
ALTER TABLE `campus_env_tracking`
  ADD PRIMARY KEY (`cet_no`),
  ADD KEY `idx_cet_complaint` (`cmp_env_com_no`),
  ADD KEY `idx_cet_changed_by` (`changed_by_user_id`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`cat_no`),
  ADD UNIQUE KEY `uq_categories_name` (`cat_name`);

--
-- Indexes for table `classes`
--
ALTER TABLE `classes`
  ADD PRIMARY KEY (`cls_no`),
  ADD UNIQUE KEY `uq_classes_cl_name` (`cl_name`),
  ADD KEY `idx_classes_dept_no` (`dept_no`),
  ADD KEY `idx_classes_camp_no` (`camp_no`);

--
-- Indexes for table `class_issues`
--
ALTER TABLE `class_issues`
  ADD PRIMARY KEY (`cl_issue_id`),
  ADD KEY `idx_class_issues_cat_no` (`cat_no`);

--
-- Indexes for table `class_issues_complaints`
--
ALTER TABLE `class_issues_complaints`
  ADD PRIMARY KEY (`cl_is_co_no`),
  ADD KEY `idx_class_issues_complaints_issue` (`cl_issue_id`),
  ADD KEY `idx_class_issues_complaints_lead` (`lead_id`);

--
-- Indexes for table `class_issue_assign`
--
ALTER TABLE `class_issue_assign`
  ADD PRIMARY KEY (`cia_no`),
  ADD UNIQUE KEY `uq_class_issue_assign_complaint` (`cl_is_co_no`),
  ADD KEY `idx_class_issue_assign_assigned_to` (`assigned_to_user_id`);

--
-- Indexes for table `class_issue_tracking`
--
ALTER TABLE `class_issue_tracking`
  ADD PRIMARY KEY (`cit_no`),
  ADD KEY `idx_cit_complaint` (`cl_is_co_no`),
  ADD KEY `idx_cit_changed_by` (`changed_by_user_id`);

--
-- Indexes for table `coursework_deadlines`
--
ALTER TABLE `coursework_deadlines`
  ADD PRIMARY KEY (`cwd_no`),
  ADD UNIQUE KEY `uq_coursework_deadlines_aa_no` (`aa_no`),
  ADD KEY `idx_cwd_set_by` (`set_by_user_id`);

--
-- Indexes for table `departments`
--
ALTER TABLE `departments`
  ADD PRIMARY KEY (`dept_no`),
  ADD UNIQUE KEY `uq_departments_name` (`name`),
  ADD KEY `idx_departments_faculty_no` (`faculty_no`);

--
-- Indexes for table `exams`
--
ALTER TABLE `exams`
  ADD PRIMARY KEY (`ex_no`),
  ADD UNIQUE KEY `uq_exams_exam` (`Exam`);

--
-- Indexes for table `exam_appeals`
--
ALTER TABLE `exam_appeals`
  ADD PRIMARY KEY (`ea_no`),
  ADD KEY `idx_ea_sc_no` (`sc_no`),
  ADD KEY `idx_ea_aa_no` (`aa_no`),
  ADD KEY `idx_ea_at_no` (`at_no`);

--
-- Indexes for table `exam_appeal_assign`
--
ALTER TABLE `exam_appeal_assign`
  ADD PRIMARY KEY (`assign_no`),
  ADD KEY `idx_eaa_eas_no` (`eas_no`),
  ADD KEY `idx_eaa_assigned_to` (`assigned_to_user_id`);

--
-- Indexes for table `exam_appeal_subjects`
--
ALTER TABLE `exam_appeal_subjects`
  ADD PRIMARY KEY (`eas_no`),
  ADD KEY `idx_eas_ea_no` (`ea_no`),
  ADD KEY `idx_eas_sub_cl_no` (`sub_cl_no`);

--
-- Indexes for table `exam_appeal_tracking`
--
ALTER TABLE `exam_appeal_tracking`
  ADD PRIMARY KEY (`track_no`),
  ADD KEY `idx_eat_eas_no` (`eas_no`),
  ADD KEY `idx_eat_changed_by` (`changed_by`);

--
-- Indexes for table `exam_officer_tasks`
--
ALTER TABLE `exam_officer_tasks`
  ADD PRIMARY KEY (`eot_no`),
  ADD KEY `idx_eot_aa_no` (`aa_no`),
  ADD KEY `idx_eot_assigned_to` (`assigned_to_user_id`),
  ADD KEY `idx_eot_target_dept_no` (`target_dept_no`),
  ADD KEY `idx_eot_target_cls_no` (`target_cls_no`),
  ADD KEY `idx_eot_target_sem_no` (`target_sem_no`),
  ADD KEY `idx_eot_target_acy_no` (`target_acy_no`),
  ADD KEY `idx_eot_created_by` (`created_by_user_id`);

--
-- Indexes for table `exam_register`
--
ALTER TABLE `exam_register`
  ADD PRIMARY KEY (`er_no`),
  ADD KEY `idx_er_ex_no` (`ex_no`),
  ADD KEY `idx_er_sem_no` (`sem_no`),
  ADD KEY `idx_er_acy_no` (`acy_no`);

--
-- Indexes for table `faculties`
--
ALTER TABLE `faculties`
  ADD PRIMARY KEY (`faculty_no`),
  ADD UNIQUE KEY `uq_faculties_name` (`name`);

--
-- Indexes for table `id_sequences_year`
--
ALTER TABLE `id_sequences_year`
  ADD PRIMARY KEY (`seq_key`);

--
-- Indexes for table `leaders`
--
ALTER TABLE `leaders`
  ADD PRIMARY KEY (`lead_id`),
  ADD UNIQUE KEY `uq_leaders_cls_no` (`cls_no`),
  ADD UNIQUE KEY `uq_leaders_std_id` (`std_id`),
  ADD KEY `idx_leaders_cls_no` (`cls_no`),
  ADD KEY `idx_leaders_std_id` (`std_id`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`msg_no`),
  ADD KEY `idx_messages_sender` (`sender_user_id`),
  ADD KEY `idx_messages_module` (`module`);

--
-- Indexes for table `message_groups`
--
ALTER TABLE `message_groups`
  ADD PRIMARY KEY (`mg_no`),
  ADD UNIQUE KEY `uq_message_groups_name` (`group_name`),
  ADD KEY `idx_mg_created_by` (`created_by_user_id`);

--
-- Indexes for table `message_group_members`
--
ALTER TABLE `message_group_members`
  ADD PRIMARY KEY (`mgm_no`),
  ADD UNIQUE KEY `uq_mgm_once` (`mg_no`,`user_id`),
  ADD KEY `idx_mgm_mg_no` (`mg_no`),
  ADD KEY `idx_mgm_user_id` (`user_id`);

--
-- Indexes for table `message_recipients`
--
ALTER TABLE `message_recipients`
  ADD PRIMARY KEY (`mr_no`),
  ADD UNIQUE KEY `uq_message_recipients_once` (`msg_no`,`receiver_user_id`),
  ADD KEY `idx_mr_msg_no` (`msg_no`),
  ADD KEY `idx_mr_receiver` (`receiver_user_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`not_no`),
  ADD KEY `idx_notifications_receiver` (`receiver_user_id`),
  ADD KEY `idx_notifications_module` (`module`);

--
-- Indexes for table `parents`
--
ALTER TABLE `parents`
  ADD PRIMARY KEY (`parent_no`);

--
-- Indexes for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `token` (`token`),
  ADD KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`);

--
-- Indexes for table `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`role_id`),
  ADD UNIQUE KEY `uq_roles_role_name` (`role_name`);

--
-- Indexes for table `school`
--
ALTER TABLE `school`
  ADD PRIMARY KEY (`sch_no`),
  ADD UNIQUE KEY `uq_school_name` (`name`);

--
-- Indexes for table `semesters`
--
ALTER TABLE `semesters`
  ADD PRIMARY KEY (`sem_no`),
  ADD UNIQUE KEY `uq_semesters_name` (`semister_name`);

--
-- Indexes for table `shifts`
--
ALTER TABLE `shifts`
  ADD PRIMARY KEY (`shift_no`),
  ADD UNIQUE KEY `shiftName` (`shiftName`);

--
-- Indexes for table `students`
--
ALTER TABLE `students`
  ADD PRIMARY KEY (`std_id`),
  ADD UNIQUE KEY `uq_students_user_id` (`user_id`),
  ADD UNIQUE KEY `uq_students_student_id` (`student_id`),
  ADD KEY `idx_students_add_no` (`add_no`),
  ADD KEY `idx_students_parent_no` (`parent_no`),
  ADD KEY `idx_students_sch_no` (`sch_no`),
  ADD KEY `fk_students_shift` (`shift_no`);

--
-- Indexes for table `student_initial_credentials`
--
ALTER TABLE `student_initial_credentials`
  ADD PRIMARY KEY (`cred_no`),
  ADD UNIQUE KEY `uq_sic_user_id` (`user_id`),
  ADD UNIQUE KEY `uq_sic_std_id` (`std_id`),
  ADD UNIQUE KEY `uq_sic_username` (`username`);

--
-- Indexes for table `studet_classes`
--
ALTER TABLE `studet_classes`
  ADD PRIMARY KEY (`sc_no`),
  ADD KEY `idx_student_classes_cls_no` (`cls_no`),
  ADD KEY `idx_student_classes_std_id` (`std_id`),
  ADD KEY `idx_student_classes_sem_no` (`sem_no`),
  ADD KEY `idx_student_classes_acy_no` (`acy_no`);

--
-- Indexes for table `subjects`
--
ALTER TABLE `subjects`
  ADD PRIMARY KEY (`sub_no`),
  ADD UNIQUE KEY `uq_subjects_code` (`code`);

--
-- Indexes for table `subject_class`
--
ALTER TABLE `subject_class`
  ADD PRIMARY KEY (`sub_cl_no`),
  ADD KEY `idx_subject_class_sub_no` (`sub_no`),
  ADD KEY `idx_subject_class_cls_no` (`cls_no`),
  ADD KEY `idx_subject_class_teacher_no` (`teacher_no`);

--
-- Indexes for table `teachers`
--
ALTER TABLE `teachers`
  ADD PRIMARY KEY (`teacher_no`),
  ADD UNIQUE KEY `uq_teachers_user_id` (`user_id`),
  ADD UNIQUE KEY `uq_teachers_teacher_id` (`teacher_id`);

--
-- Indexes for table `teacher_initial_credentials`
--
ALTER TABLE `teacher_initial_credentials`
  ADD PRIMARY KEY (`cred_no`),
  ADD UNIQUE KEY `uq_tic_user_id` (`user_id`),
  ADD UNIQUE KEY `uq_tic_teacher_no` (`teacher_no`),
  ADD UNIQUE KEY `uq_tic_username` (`username`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `uq_users_username` (`username`),
  ADD KEY `idx_users_role_id` (`role_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `academics`
--
ALTER TABLE `academics`
  MODIFY `acy_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `address`
--
ALTER TABLE `address`
  MODIFY `add_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `allowed_exam_apeal_types`
--
ALTER TABLE `allowed_exam_apeal_types`
  MODIFY `aeat_no` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `allow_apeals`
--
ALTER TABLE `allow_apeals`
  MODIFY `aa_no` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `appeal_types`
--
ALTER TABLE `appeal_types`
  MODIFY `at_no` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `campuses`
--
ALTER TABLE `campuses`
  MODIFY `camp_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `campus_enviroment`
--
ALTER TABLE `campus_enviroment`
  MODIFY `camp_env_no` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `campus_envo_complaints`
--
ALTER TABLE `campus_envo_complaints`
  MODIFY `cmp_env_com_no` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `campus_env_assign`
--
ALTER TABLE `campus_env_assign`
  MODIFY `cea_no` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `campus_env_support`
--
ALTER TABLE `campus_env_support`
  MODIFY `ces_no` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `campus_env_tracking`
--
ALTER TABLE `campus_env_tracking`
  MODIFY `cet_no` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `cat_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `classes`
--
ALTER TABLE `classes`
  MODIFY `cls_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `class_issues`
--
ALTER TABLE `class_issues`
  MODIFY `cl_issue_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `class_issues_complaints`
--
ALTER TABLE `class_issues_complaints`
  MODIFY `cl_is_co_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `class_issue_assign`
--
ALTER TABLE `class_issue_assign`
  MODIFY `cia_no` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `class_issue_tracking`
--
ALTER TABLE `class_issue_tracking`
  MODIFY `cit_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `coursework_deadlines`
--
ALTER TABLE `coursework_deadlines`
  MODIFY `cwd_no` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `departments`
--
ALTER TABLE `departments`
  MODIFY `dept_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `exams`
--
ALTER TABLE `exams`
  MODIFY `ex_no` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `exam_appeals`
--
ALTER TABLE `exam_appeals`
  MODIFY `ea_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `exam_appeal_assign`
--
ALTER TABLE `exam_appeal_assign`
  MODIFY `assign_no` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `exam_appeal_subjects`
--
ALTER TABLE `exam_appeal_subjects`
  MODIFY `eas_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `exam_appeal_tracking`
--
ALTER TABLE `exam_appeal_tracking`
  MODIFY `track_no` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `exam_officer_tasks`
--
ALTER TABLE `exam_officer_tasks`
  MODIFY `eot_no` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `exam_register`
--
ALTER TABLE `exam_register`
  MODIFY `er_no` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `faculties`
--
ALTER TABLE `faculties`
  MODIFY `faculty_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `leaders`
--
ALTER TABLE `leaders`
  MODIFY `lead_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `msg_no` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `message_groups`
--
ALTER TABLE `message_groups`
  MODIFY `mg_no` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `message_group_members`
--
ALTER TABLE `message_group_members`
  MODIFY `mgm_no` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `message_recipients`
--
ALTER TABLE `message_recipients`
  MODIFY `mr_no` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `not_no` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `parents`
--
ALTER TABLE `parents`
  MODIFY `parent_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT for table `roles`
--
ALTER TABLE `roles`
  MODIFY `role_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `school`
--
ALTER TABLE `school`
  MODIFY `sch_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `semesters`
--
ALTER TABLE `semesters`
  MODIFY `sem_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `shifts`
--
ALTER TABLE `shifts`
  MODIFY `shift_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `students`
--
ALTER TABLE `students`
  MODIFY `std_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `student_initial_credentials`
--
ALTER TABLE `student_initial_credentials`
  MODIFY `cred_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `studet_classes`
--
ALTER TABLE `studet_classes`
  MODIFY `sc_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `subjects`
--
ALTER TABLE `subjects`
  MODIFY `sub_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT for table `subject_class`
--
ALTER TABLE `subject_class`
  MODIFY `sub_cl_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `teachers`
--
ALTER TABLE `teachers`
  MODIFY `teacher_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=76;

--
-- AUTO_INCREMENT for table `teacher_initial_credentials`
--
ALTER TABLE `teacher_initial_credentials`
  MODIFY `cred_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `allow_apeals`
--
ALTER TABLE `allow_apeals`
  ADD CONSTRAINT `fk_allow_appeals_exam_register` FOREIGN KEY (`er_no`) REFERENCES `exam_register` (`er_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_allow_appeals_hoe_user` FOREIGN KEY (`HOE_no`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `appeal_types`
--
ALTER TABLE `appeal_types`
  ADD CONSTRAINT `fk_at_allowed_types` FOREIGN KEY (`aeat_no`) REFERENCES `allowed_exam_apeal_types` (`aeat_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_at_exam_register` FOREIGN KEY (`er_no`) REFERENCES `exam_register` (`er_no`) ON UPDATE CASCADE;

--
-- Constraints for table `campus_enviroment`
--
ALTER TABLE `campus_enviroment`
  ADD CONSTRAINT `fk_campus_env_categories` FOREIGN KEY (`cat_no`) REFERENCES `categories` (`cat_no`) ON UPDATE CASCADE;

--
-- Constraints for table `campus_envo_complaints`
--
ALTER TABLE `campus_envo_complaints`
  ADD CONSTRAINT `fk_cec_env` FOREIGN KEY (`camp_env_no`) REFERENCES `campus_enviroment` (`camp_env_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_cec_student` FOREIGN KEY (`std_id`) REFERENCES `students` (`std_id`) ON UPDATE CASCADE;

--
-- Constraints for table `campus_env_assign`
--
ALTER TABLE `campus_env_assign`
  ADD CONSTRAINT `fk_cea_complaint` FOREIGN KEY (`cmp_env_com_no`) REFERENCES `campus_envo_complaints` (`cmp_env_com_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_cea_users` FOREIGN KEY (`assigned_to_user_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `campus_env_support`
--
ALTER TABLE `campus_env_support`
  ADD CONSTRAINT `fk_ces_complaint` FOREIGN KEY (`cmp_env_com_no`) REFERENCES `campus_envo_complaints` (`cmp_env_com_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ces_student` FOREIGN KEY (`std_id`) REFERENCES `students` (`std_id`) ON UPDATE CASCADE;

--
-- Constraints for table `campus_env_tracking`
--
ALTER TABLE `campus_env_tracking`
  ADD CONSTRAINT `fk_cet_complaint` FOREIGN KEY (`cmp_env_com_no`) REFERENCES `campus_envo_complaints` (`cmp_env_com_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_cet_users` FOREIGN KEY (`changed_by_user_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `classes`
--
ALTER TABLE `classes`
  ADD CONSTRAINT `fk_classes_campuses` FOREIGN KEY (`camp_no`) REFERENCES `campuses` (`camp_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_classes_departments` FOREIGN KEY (`dept_no`) REFERENCES `departments` (`dept_no`) ON UPDATE CASCADE;

--
-- Constraints for table `class_issues`
--
ALTER TABLE `class_issues`
  ADD CONSTRAINT `fk_class_issues_categories` FOREIGN KEY (`cat_no`) REFERENCES `categories` (`cat_no`) ON UPDATE CASCADE;

--
-- Constraints for table `class_issues_complaints`
--
ALTER TABLE `class_issues_complaints`
  ADD CONSTRAINT `fk_cic_issue` FOREIGN KEY (`cl_issue_id`) REFERENCES `class_issues` (`cl_issue_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_cic_leader` FOREIGN KEY (`lead_id`) REFERENCES `leaders` (`lead_id`) ON UPDATE CASCADE;

--
-- Constraints for table `class_issue_assign`
--
ALTER TABLE `class_issue_assign`
  ADD CONSTRAINT `fk_cia_complaint` FOREIGN KEY (`cl_is_co_no`) REFERENCES `class_issues_complaints` (`cl_is_co_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_cia_users` FOREIGN KEY (`assigned_to_user_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `class_issue_tracking`
--
ALTER TABLE `class_issue_tracking`
  ADD CONSTRAINT `fk_cit_complaint` FOREIGN KEY (`cl_is_co_no`) REFERENCES `class_issues_complaints` (`cl_is_co_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_cit_users` FOREIGN KEY (`changed_by_user_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `coursework_deadlines`
--
ALTER TABLE `coursework_deadlines`
  ADD CONSTRAINT `fk_cwd_allow_appeals` FOREIGN KEY (`aa_no`) REFERENCES `allow_apeals` (`aa_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_cwd_user` FOREIGN KEY (`set_by_user_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `departments`
--
ALTER TABLE `departments`
  ADD CONSTRAINT `fk_departments_faculties` FOREIGN KEY (`faculty_no`) REFERENCES `faculties` (`faculty_no`) ON UPDATE CASCADE;

--
-- Constraints for table `exam_appeals`
--
ALTER TABLE `exam_appeals`
  ADD CONSTRAINT `fk_ea_allow_appeals` FOREIGN KEY (`aa_no`) REFERENCES `allow_apeals` (`aa_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ea_appeal_types` FOREIGN KEY (`at_no`) REFERENCES `appeal_types` (`at_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ea_student_classes` FOREIGN KEY (`sc_no`) REFERENCES `studet_classes` (`sc_no`) ON UPDATE CASCADE;

--
-- Constraints for table `exam_appeal_assign`
--
ALTER TABLE `exam_appeal_assign`
  ADD CONSTRAINT `fk_eaa_subject` FOREIGN KEY (`eas_no`) REFERENCES `exam_appeal_subjects` (`eas_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_eaa_user` FOREIGN KEY (`assigned_to_user_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `exam_appeal_subjects`
--
ALTER TABLE `exam_appeal_subjects`
  ADD CONSTRAINT `fk_eas_exam_appeals` FOREIGN KEY (`ea_no`) REFERENCES `exam_appeals` (`ea_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_eas_subject_class` FOREIGN KEY (`sub_cl_no`) REFERENCES `subject_class` (`sub_cl_no`) ON UPDATE CASCADE;

--
-- Constraints for table `exam_appeal_tracking`
--
ALTER TABLE `exam_appeal_tracking`
  ADD CONSTRAINT `fk_eat_subject` FOREIGN KEY (`eas_no`) REFERENCES `exam_appeal_subjects` (`eas_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_eat_user` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `exam_officer_tasks`
--
ALTER TABLE `exam_officer_tasks`
  ADD CONSTRAINT `fk_eot_allow_appeals` FOREIGN KEY (`aa_no`) REFERENCES `allow_apeals` (`aa_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_eot_assigned_to_user` FOREIGN KEY (`assigned_to_user_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_eot_created_by_user` FOREIGN KEY (`created_by_user_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_eot_target_acy` FOREIGN KEY (`target_acy_no`) REFERENCES `academics` (`acy_no`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_eot_target_class` FOREIGN KEY (`target_cls_no`) REFERENCES `classes` (`cls_no`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_eot_target_dept` FOREIGN KEY (`target_dept_no`) REFERENCES `departments` (`dept_no`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_eot_target_sem` FOREIGN KEY (`target_sem_no`) REFERENCES `semesters` (`sem_no`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `exam_register`
--
ALTER TABLE `exam_register`
  ADD CONSTRAINT `fk_er_academics` FOREIGN KEY (`acy_no`) REFERENCES `academics` (`acy_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_er_exams` FOREIGN KEY (`ex_no`) REFERENCES `exams` (`ex_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_er_semesters` FOREIGN KEY (`sem_no`) REFERENCES `semesters` (`sem_no`) ON UPDATE CASCADE;

--
-- Constraints for table `leaders`
--
ALTER TABLE `leaders`
  ADD CONSTRAINT `fk_leaders_classes` FOREIGN KEY (`cls_no`) REFERENCES `classes` (`cls_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_leaders_students` FOREIGN KEY (`std_id`) REFERENCES `students` (`std_id`) ON UPDATE CASCADE;

--
-- Constraints for table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `fk_messages_users` FOREIGN KEY (`sender_user_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `message_groups`
--
ALTER TABLE `message_groups`
  ADD CONSTRAINT `fk_mg_users` FOREIGN KEY (`created_by_user_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `message_group_members`
--
ALTER TABLE `message_group_members`
  ADD CONSTRAINT `fk_mgm_groups` FOREIGN KEY (`mg_no`) REFERENCES `message_groups` (`mg_no`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_mgm_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `message_recipients`
--
ALTER TABLE `message_recipients`
  ADD CONSTRAINT `fk_mr_messages` FOREIGN KEY (`msg_no`) REFERENCES `messages` (`msg_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_mr_users` FOREIGN KEY (`receiver_user_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `fk_notifications_users` FOREIGN KEY (`receiver_user_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `students`
--
ALTER TABLE `students`
  ADD CONSTRAINT `fk_students_address` FOREIGN KEY (`add_no`) REFERENCES `address` (`add_no`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_students_parents` FOREIGN KEY (`parent_no`) REFERENCES `parents` (`parent_no`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_students_school` FOREIGN KEY (`sch_no`) REFERENCES `school` (`sch_no`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_students_shift` FOREIGN KEY (`shift_no`) REFERENCES `shifts` (`shift_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_students_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `student_initial_credentials`
--
ALTER TABLE `student_initial_credentials`
  ADD CONSTRAINT `fk_sic_students` FOREIGN KEY (`std_id`) REFERENCES `students` (`std_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_sic_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `studet_classes`
--
ALTER TABLE `studet_classes`
  ADD CONSTRAINT `fk_student_classes_academics` FOREIGN KEY (`acy_no`) REFERENCES `academics` (`acy_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_student_classes_classes` FOREIGN KEY (`cls_no`) REFERENCES `classes` (`cls_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_student_classes_semesters` FOREIGN KEY (`sem_no`) REFERENCES `semesters` (`sem_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_student_classes_students` FOREIGN KEY (`std_id`) REFERENCES `students` (`std_id`) ON UPDATE CASCADE;

--
-- Constraints for table `subject_class`
--
ALTER TABLE `subject_class`
  ADD CONSTRAINT `fk_subject_class_classes` FOREIGN KEY (`cls_no`) REFERENCES `classes` (`cls_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_subject_class_subjects` FOREIGN KEY (`sub_no`) REFERENCES `subjects` (`sub_no`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_subject_class_teachers` FOREIGN KEY (`teacher_no`) REFERENCES `teachers` (`teacher_no`) ON UPDATE CASCADE;

--
-- Constraints for table `teachers`
--
ALTER TABLE `teachers`
  ADD CONSTRAINT `fk_teachers_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `teacher_initial_credentials`
--
ALTER TABLE `teacher_initial_credentials`
  ADD CONSTRAINT `fk_tic_teachers` FOREIGN KEY (`teacher_no`) REFERENCES `teachers` (`teacher_no`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_tic_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `users_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `roles` (`role_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
