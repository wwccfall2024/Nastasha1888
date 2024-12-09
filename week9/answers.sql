-- Create your tables, views, functions and procedures here!
CREATE SCHEMA social;
USE social;

CREATE TABLE users (
  user_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  first_name VARCHAR(30),
  last_name VARCHAR(30),
  email VARCHAR(100),
  created_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sessions (
  session_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  user_id INT UNSIGNED,
  created_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT users_fk_sessions
    FOREIGN KEY (user_id) REFERENCES users(user_id)
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
  created_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  content VARCHAR(255),
  CONSTRAINT posts_fk_users
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE notifications (
  notification_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  user_id INT UNSIGNED,
  post_id INT UNSIGNED,
  CONSTRAINT notifications_fk_users
    FOREIGN KEY (user_id) REFERENCES users(user_id),
  CONSTRAINT notifications_fk_posts
    FOREIGN KEY (post_id) REFERENCES posts(post_id)
  ON DELETE CASCADE
);

CREATE  OR REPLACE VIEW notification_posts AS
SELECT 
    n.user_id,
    u.first_name,
    u.last_name,
    p.post_id,
    p.content
FROM notifications n
JOIN users u ON u.user_id = (
    SELECT user_id 
    FROM posts 
    WHERE post_id = n.post_id
)
JOIN posts p ON p.post_id = n.post_id
ORDER BY p.post_id;

DELIMITER ;;

CREATE TRIGGER after_user_insert 
AFTER INSERT ON users
FOR EACH ROW
BEGIN
    INSERT INTO posts (user_id, content)
    VALUES (NEW.user_id, CONCAT(NEW.first_name, ' ', NEW.last_name, ' just joined!'));
    
    INSERT INTO notifications (user_id, post_id)
    SELECT u.user_id, LAST_INSERT_ID()
    FROM users u
    WHERE u.user_id != NEW.user_id;
END;;

CREATE PROCEDURE add_post(IN user_id INT UNSIGNED, IN content VARCHAR(255))
BEGIN
    INSERT INTO posts (user_id, content)
    VALUES (user_id, content);
    
    INSERT INTO notifications (user_id, post_id)
    SELECT friend_id, LAST_INSERT_ID()
    FROM friends f
    WHERE f.user_id = user_id;
END;;
CREATE EVENT clean_old_sessions
ON SCHEDULE EVERY 10 SECOND
DO
    DELETE FROM sessions 
    WHERE updated_on < DATE_SUB(NOW(), INTERVAL 2 HOUR)
    AND created_on < DATE_SUB(NOW(), INTERVAL 2 HOUR);;

DELIMITER ;
