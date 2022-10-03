CREATE SCHEMA softuni_imdb;

USE softuni_imdb;

-- Section 1: Data Definition Language (DDL)
-- 1. Table Design

CREATE TABLE `countries` (
id INT PRIMARY KEY AUTO_INCREMENT,
`name` VARCHAR(30) NOT NULL UNIQUE,
`continent` VARCHAR(30) NOT NULL,
`currency` VARCHAR(5) NOT NULL );

CREATE TABLE `genres` (
id INT PRIMARY KEY AUTO_INCREMENT,
`name` VARCHAR(50) NOT NULL UNIQUE );

CREATE TABLE `actors` (
id INT PRIMARY KEY AUTO_INCREMENT,
`first_name` VARCHAR(50) NOT NULL,
`last_name` VARCHAR(50) NOT NULL,
`birthdate` DATE NOT NULL,
`height` INT,
`awards` INT,
`country_id` INT NOT NULL,
CONSTRAINT fk_actor_country
FOREIGN KEY (country_id) REFERENCES countries(id));

CREATE TABLE `movies_additional_info` (
id INT PRIMARY KEY AUTO_INCREMENT,
`rating` DECIMAL(10, 2) NOT NULL,
`runtime` INT NOT NULL,
`picture_url` VARCHAR(80) NOT NULL,
`budget` DECIMAL(10, 2),
`release_date` DATE NOT NULL,
`has_subtitles` TINYINT(1),
`description` TEXT );

CREATE TABLE `movies` (
id INT PRIMARY KEY AUTO_INCREMENT,
`title` VARCHAR(70) NOT NULL UNIQUE,
`country_id` INT NOT NULL,
`movie_info_id` INT NOT NULL UNIQUE,
CONSTRAINT fk_movie_country
FOREIGN KEY (country_id) REFERENCES countries(id),
CONSTRAINT fk_movie_info
FOREIGN KEY (movie_info_id) REFERENCES movies_additional_info(id));

CREATE TABlE `movies_actors` (
`movie_id` INT,
`actor_id` INT,
CONSTRAINT fk_movie
FOREIGN KEY (movie_id) REFERENCES movies(id),
CONSTRAINT fk_actor
FOREIGN KEY (actor_id) REFERENCES actors(id));

CREATE TABLE `genres_movies` (
`genre_id` INT,
`movie_id` INT,
KEY pk_genres_movies(genre_id, movie_id),
CONSTRAINT fk_genre
FOREIGN KEY (genre_id) REFERENCES genres(id),
CONSTRAINT fk_movies
FOREIGN KEY (movie_id) REFERENCES movies(id));

-- Section 2: Data Manipulation Language (DML)
-- 2. Insert

INSERT INTO actors(first_name, last_name, birtdate, height, awards, country_id)
SELECT reverse(first_name),
       reverse(last_name),
       date_sub(birtdate, INTERVAL 2 DAY),
       height + 10,
       country_id,
       (SELECT id FROM countries WHERE `name` LIKE 'Armenia')
FROM actors
WHERE id <= 10;

-- 3. Update

UPDATE movies_additional_info
SET runtime = CASE
WHEN runtime - 10 < 0
THEN 0
ELSE runtime - 10
END
WHERE id BETWEEN 15 AND 25;

-- 4. Delete

DELETE c
FROM countries AS c
LEFT JOIN movies AS m
ON c.id = m.country_id
WHERE m.country_id IS NULL;

-- Section 3: Querying
-- 5. Countries

SELECT * FROM countries
ORDER BY currency DESC, id;

-- 6. Old movies

SELECT id, title, runtime, budget, release_date FROM movies_additional_info
JOIN movies USING (id)
WHERE year(release_date) BETWEEN 1996 AND 1999
ORDER BY runtime, id
LIMIT 20;

-- 7. Movie casting

SELECT
     CONCAT_WS(' ', first_name, last_name) AS full_name,
     CONCAT(REVERSE(last_name), LENGTH(last_name), '@cast.com') AS email,
     2022 - year(birthdate) AS age,
     height
FROM actors
LEFT JOIN movies_actors ON id = movies_actors.actor_id
WHERE actor_id IS NULL
ORDER BY height;

-- 8. International festival

SELECT `name`, count(movies.id) AS movies_count
FROM movies
LEFT JOIN countries
ON movies.country_id = countries.id
GROUP BY movies.country_id HAVING movies_count >= 7
ORDER BY countries.`name` DESC;     

-- 9. Rating system

SELECT movies.title,
	   CASE 
       WHEN i.rating <= 4 THEN 'poor'
       WHEN i.rating <= 7 THEN 'good'
       ELSE 'excellent'
       END AS rating,
       IF(i.has_subtitles, 'english', '-') AS subtitles, i.budget
FROM movies
JOIN movies_additional_info AS i USING (id)
ORDER BY i.budget DESC;

-- Section 4: Programmability
-- 10. History movies

CREATE FUNCTION udf_actor_history_movies_count(full_name VARCHAR(50))
RETURNS INT DETERMINISTIC
BEGIN 
     DECLARE history_movies INT
     SET history_movies := (
     SELECT count(movies_actors.movie_id) FROM movie_actors JOIN actors
     ON movies_actors.actor_id = actors.id
     JOIN genres_movies 
     ON genres_movies.movie_id = movies_actors.movie_id
     JOIN genres
     ON genres_movies.genre_id = genres.id
     WHERE CONCAT_WS(' ', actors.first_name, actors.last_name) = full_name AND genres.`name` = 'History'
     GROUP BY movies_actors.id);
     
     RETURN history_movies;
     END;
     
     -- 11. Movie awards

CREATE PROCEDURE udp_award_movie(movie_title VARCHAR(50))
BEGIN
	UPDATE actors AS a
	JOIN movies_actors AS ma
    ON a.id = ma.actor_id
    JOIN movies AS m
    ON ma.movie_id = m.id
    SET a.awards = a.awards + 1
	WHERE m.title = movie_title;
END;

