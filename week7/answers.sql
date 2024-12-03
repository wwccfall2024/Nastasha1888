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
level TINYINT UNSIGNED NOT NULL,
FOREIGN KEY(player_id)
REFERENCES players(player_id)
);

CREATE TABLE winners (
character_id INT UNSIGNED PRIMARY KEY,
name VARCHAR(40) NOT NULL,
FOREIGN KEY(character_id)
REFERENCES characters(character_id)
);

CREATE TABLE character_stats (
character_id INT UNSIGNED PRIMARY KEY,
health INT UNSIGNED NOT NULL,
armor INT UNSIGNED NOT NULL,
FOREIGN KEY(character_id)
REFERENCES characters(character_id) ON DELETE CASCADE
);

CREATE TABLE teams (
team_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
name VARCHAR(40) NOT NULL
);

CREATE TABLE team_members (
team_memeber_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
team_id INT UNSIGNED,
character_id INT UNSIGNED,
FOREIGN KEY(team_id)
REFERENCES teams(team_id),
FOREIGN KEY(character_id)
REFERENCES characters(character_id)
ON DELETE CASCADE
);

CREATE TABLE items (
item_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
name VARCHAR(40) NOT NULL,
armor INT UNSIGNED NOT NULL,
damage INT UNSIGNED NOT NULL
);

CREATE TABLE inventory (
inventory_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
character_id INT UNSIGNED,
item_id INT UNSIGNED,
FOREIGN KEY(character_id) 
REFERENCES characters(character_id) ON DELETE CASCADE,
FOREIGN KEY(item_id) 
REFERENCES items(item_id)
);

CREATE TABLE equipped (
equipped_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
character_id INT UNSIGNED,
item_id INT UNSIGNED,
FOREIGN KEY(character_id) 
REFERENCES characters(character_id)
ON DELETE CASCADE,
FOREIGN KEY(item_id) 
REFERENCES items(item_id)
);

CREATE OR REPLACE VIEW character_items AS 
SELECT c.character_id,
    c.name AS character_name,
    i.name AS item_name,
    i.armor, i.damage
FROM characters c
LEFT JOIN inventory inv ON c.character_id = inv.character_id
LEFT JOIN items i ON inv.item_id = i.item_id
UNION
SELECT c.character_id,
    c.name AS character_name,
    i.name AS item_name,
    i.armor, i.damage
FROM characters c
LEFT JOIN equipped eq ON c.character_id = eq.character_id
LEFT JOIN items i ON eq.item_id = i.item_id
ORDER BY character_name, item_name;

CREATE OR REPLACE VIEW team_items AS 
SELECT tm.team_id,
       t.name AS team_name,
       i.name AS item_name,
       i.armor, i.damage
FROM team_members tm
JOIN teams t ON tm.team_id = t.team_id
JOIN characters c ON tm.character_id = c.character_id
LEFT JOIN inventory inv ON c.character_id = inv.character_id
LEFT JOIN items i ON inv.item_id = i.item_id
WHERE i.name IS NOT NULL
UNION
SELECT tm.team_id,
       t.name AS team_name,
       i.name AS item_name,
       i.armor, i.damage
FROM team_members tm
JOIN teams t ON tm.team_id = t.team_id
JOIN characters c ON tm.character_id = c.character_id
LEFT JOIN equipped e ON c.character_id = e.character_id
LEFT JOIN items i ON e.item_id = i.item_id
WHERE i.name IS NOT NULL
ORDER BY team_name, item_name;

DELIMITER ;;

CREATE FUNCTION armor_total(character_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE total_armor INT DEFAULT 0;

    SELECT armor INTO total_armor
    FROM character_stats
    WHERE character_id = character_id;

    SELECT COALESCE(SUM(i.armor), 0) INTO total_armor
    FROM equipped e
    JOIN items i ON e.item_id = i.item_id
    WHERE e.character_id = character_id
    GROUP BY e.character_id;

    RETURN total_armor;
END;;

CREATE PROCEDURE attack(
    IN id_of_character_being_attacked INT,
    IN id_of_equipped_item_used_for_attack INT
)
BEGIN
    DECLARE total_damage INT;
    DECLARE damage INT;
    DECLARE armor INT;
    DECLARE character_health INT;
    
    DECLARE health_cursor CURSOR FOR 
            SELECT health 
            FROM character_stats 
            WHERE character_id = id_of_character_being_attacked;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET character_health = -1;

    SELECT damage INTO damage
    FROM items
    WHERE item_id = id_of_equipped_item_used_for_attack;

    SET armor = armor_total(id_of_character_being_attacked);
	SET total_damage = damage - armor;

    IF total_damage > 0 THEN
        UPDATE character_stats
        SET health = health - total_damage
        WHERE character_id = id_of_character_being_attacked;

        OPEN health_cursor;

        FETCH health_cursor INTO character_health;

        CLOSE health_cursor;

		IF character_health <= 0 THEN
			DELETE FROM characters 
            WHERE character_id = id_of_character_being_attacked;
        END IF;
    END IF;
END;;

CREATE PROCEDURE equip(
    IN inventory_id INT
)
BEGIN
    DECLARE character_id INT;
    DECLARE item_id INT;
    
    SELECT character_id, item_id
    INTO character_id, item_id
    FROM inventory
    WHERE inventory_id = inventory_id;

    INSERT INTO equipped (character_id, item_id)
    VALUES (character_id, item_id);

    DELETE FROM inventory
    WHERE inventory_id = inventory_id;
END;;

CREATE PROCEDURE unequip(
    IN equipped_id INT
)
BEGIN
    DECLARE character_id INT;
    DECLARE item_id INT;

    SELECT character_id, item_id
    INTO character_id, item_id
    FROM equipped
    WHERE equipped_id = equipped_id;

    INSERT INTO inventory (character_id, item_id)
    VALUES (character_id, item_id);

    DELETE FROM equipped
    WHERE equipped_id = equipped_id;
END;;

CREATE PROCEDURE set_winners(
    IN team_id INT
)
BEGIN
    DECLARE character_id INT;
    DECLARE done INT DEFAULT 0;

    DECLARE winner_cursor CURSOR FOR 
        SELECT c.character_id
        FROM team_members tm
        JOIN characters c ON tm.character_id = c.character_id
        WHERE tm.team_id = team_id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    DELETE FROM winners;

    OPEN winner_cursor;

    read_loop: LOOP
        FETCH winner_cursor INTO character_id;

        IF done THEN
            LEAVE read_loop;
        END IF;

        INSERT IGNORE INTO winners (character_id, name)
        SELECT tm.character_id, c.name
        FROM team_members tm
        JOIN characters c ON tm.character_id = c.character_id
        WHERE tm.team_id = team_id;
    END LOOP;

    CLOSE winner_cursor;
END;;

DELIMITER ;
