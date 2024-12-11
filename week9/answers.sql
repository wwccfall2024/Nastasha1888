-- Create your tables, views, functions and procedures here!
CREATE SCHEMA social;
USE social;

CREATE TABLE users (
  user_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  first_name VARCHAR(30) NOT NULL,
  last_name VARCHAR(30) NOT NULL,
  email VARCHAR(100) NOT NULL,
  created_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE sessions (
  session_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  user_id INT UNSIGNED,
  created_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
  CONSTRAINT users_fk_sessions
    FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON DELETE CASCADE
  );

CREATE TABLE friends (
  user_friend_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  user_id INT UNSIGNED,
  friend_id INT UNSIGNED,
  CONSTRAINT friends_fk_users
    FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON DELETE CASCADE,
  CONSTRAINT friends_fk_friends
    FOREIGN KEY (friend_id) REFERENCES users(user_id)
  ON DELETE CASCADE
);

CREATE TABLE posts (
  post_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  user_id INT UNSIGNED,
  created_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
  content VARCHAR(255) NOT NULL,
  CONSTRAINT posts_fk_users
    FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON DELETE CASCADE
);

CREATE TABLE notifications (
  notification_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  user_id INT UNSIGNED,
  post_id INT UNSIGNED,
  CONSTRAINT notifications_fk_users
    FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON DELETE CASCADE,
  CONSTRAINT notifications_fk_posts
    FOREIGN KEY (post_id) REFERENCES posts(post_id)
  ON DELETE CASCADE
);

DELIMITER ;;

CREATE OR REPLACE VIEW notification_posts AS
SELECT 
    n.user_id,
    u.first_name,
    u.last_name,
    p.post_id,
    p.content
FROM notifications n
INNER JOIN posts p 
  ON p.post_id = n.post_id
INNER JOIN users u 
  ON u.user_id = p.user_id
ORDER BY p.post_id;

CREATE TRIGGER after_user_insert 
AFTER INSERT ON users
FOR EACH ROW
BEGIN

  DECLARE done INT DEFAULT FALSE;
  DECLARE current_user_id INT;
  DECLARE last_post_id INT;

  DECLARE users_cursor CURSOR FOR 
    SELECT user_id 
      FROM users 
      WHERE user_id != NEW.user_id;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  INSERT INTO posts 
    (user_id, content)
      VALUES 
    (NEW.user_id, CONCAT(NEW.first_name, ' ', NEW.last_name, ' just joined!'));

  SET last_post_id = LAST_INSERT_ID();

  OPEN users_cursor;

  users_loop: LOOP
      FETCH users_cursor INTO current_user_id;
      IF done THEN
          LEAVE users_loop;
      END IF;

      INSERT INTO notifications 
        (user_id, post_id)
      VALUES 
        (current_user_id, last_post_id);
  END LOOP;

  CLOSE users_cursor;
END;;

CREATE PROCEDURE add_post(IN p_user_id INT UNSIGNED, IN p_content VARCHAR(255))
BEGIN

    DECLARE done INT DEFAULT FALSE;
    DECLARE friend_id INT;
    DECLARE last_post_id INT;

    DECLARE friends_cursor CURSOR FOR 
      SELECT friend_id 
        FROM friends 
        WHERE user_id = p_user_id;
      UNION
      SELECT user_id
        FROM friends
        WHERE friend_id = p.user_id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    INSERT INTO posts
      (user_id, content)
    VALUES
      (p_user_id, p_content);

    SET last_post_id = LAST_INSERT_ID();

    OPEN friends_cursor;

    friends_loop: LOOP
        FETCH friends_cursor INTO friend_id;
        IF done THEN
            LEAVE friends_loop;
        END IF;

        INSERT INTO notifications 
          (user_id, post_id)
        VALUES 
          (friend_id, last_post_id);
    END LOOP;

    CLOSE friends_cursor;
END;;

CREATE EVENT clean_old_sessions
ON SCHEDULE EVERY 10 SECOND
DO
    DELETE FROM sessions 
    WHERE updated_on < DATE_SUB(NOW(), INTERVAL 2 HOUR);;

DELIMITER ;
