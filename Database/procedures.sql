DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_create_student`(IN `p_name` VARCHAR(150), IN `p_tell` VARCHAR(30), IN `p_gender` VARCHAR(15), IN `p_email` VARCHAR(150), IN `p_add_no` INT, IN `p_dob` DATE, IN `p_parent_no` INT, IN `p_register_date` DATE, IN `p_mother` VARCHAR(150), IN `p_sch_no` INT, IN `p_nira` VARCHAR(50), IN `p_status` VARCHAR(20), IN `p_access_channel` ENUM('APP','WEB','BOTH',''), OUT `o_user_id` INT, OUT `o_std_id` INT, OUT `o_student_id` VARCHAR(20), OUT `o_plain_password` VARCHAR(6))
BEGIN
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
DELIMITER ;





DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_create_teacher`(
  IN  p_name           VARCHAR(150),
  IN  p_tell           VARCHAR(30),
  IN  p_email          VARCHAR(150),
  IN  p_gender         VARCHAR(15),
  IN  p_hire_date      DATE,
  IN  p_status         VARCHAR(20),
  IN  p_access_channel ENUM('APP','WEB','BOTH',''),

  OUT o_user_id        INT,
  OUT o_teacher_no     INT,
  OUT o_teacher_id     VARCHAR(20),
  OUT o_plain_password VARCHAR(6)
)
BEGIN
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
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_generate_student_id`(
  IN  p_year INT,                 -- pass NULL for current year
  OUT p_student_id VARCHAR(20)
)
BEGIN
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
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_generate_teacher_id`(
  IN  p_year INT,                  -- NULL => current year
  OUT p_teacher_id VARCHAR(20)
)
BEGIN
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
DELIMITER ;