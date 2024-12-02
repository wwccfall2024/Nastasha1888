-- Create your tables, views, functions and procedures here!
CREATE SCHEMA destruction;
USE destruction;

CREATE TABLE players (
player_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
first_name VARCHAR(30) NOT NULL,
last_name VARCHAR(30) NOT NULL,
email VARCHAR(50) NOT NULL
);

CREATE TABLE characters (
character_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
player_id INT UNSIGNED,
name VARCHAR(40) NOT NULL,
level INT UNSIGNED NOT NULL,
FOREIGN KEY(player_id)
REFERENCES players(player_id)
);

CREATE TABLE winners (
character_id INT UNSIGNED PRIMARY KEY,
name VARCHAR(40),
FOREIGN KEY(character_id)
REFERENCES characters(character_id)
);

CREATE TABLE character_stats (
character_id INT UNSIGNED PRIMARY KEY,
health INT UNSIGNED NOT NULL,
armor INT UNSIGNED NOT NULL,
FOREIGN KEY(character_id)
REFERENCES characters(character_id)
);

CREATE TABLE teams (
team_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
name VARCHAR(40)
);

CREATE TABLE team_members (
team_memeber_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
team_id INT UNSIGNED,
character_id INT UNSIGNED,
FOREIGN KEY(team_id)
REFERENCES teams(team_id),
FOREIGN KEY(character_id)
REFERENCES characters(character_id)
);

CREATE TABLE items (
item_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
name VARCHAR(40),
armor INT UNSIGNED,
damage INT UNSIGNED
);

CREATE TABLE inventory (
inventory_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
character_id INT UNSIGNED,
item_id INT UNSIGNED,
FOREIGN KEY(character_id) 
REFERENCES characters(character_id),
FOREIGN KEY(item_id) 
REFERENCES items(item_id)
);

CREATE TABLE equipped (
equipped_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
character_id INT UNSIGNED,
item_id INT UNSIGNED,
FOREIGN KEY(character_id) 
REFERENCES characters(character_id),
FOREIGN KEY(item_id) 
REFERENCES items(item_id)
);
