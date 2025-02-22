-- ----Task #1----
CREATE SCHEMA IF NOT EXISTS pandemic;

USE pandemic;


-- ----Task #2----
-- Create countries table
CREATE TABLE countries(
id INT PRIMARY KEY AUTO_INCREMENT,
code VARCHAR(8) UNIQUE,
country VARCHAR(32) NOT NULL UNIQUE
);

-- Fill countries table
INSERT INTO countries (code, country)
SELECT DISTINCT code, entity FROM infectious_cases;

-- Create copy of infectious_cases table
CREATE TABLE infectious_cases_norm 
AS SELECT * FROM infectious_cases;

-- Add column id and country_id to infectious_cases_norm
ALTER TABLE infectious_cases_norm
ADD id INT PRIMARY KEY AUTO_INCREMENT FIRST,
ADD country_id INT AFTER id,
ADD CONSTRAINT fk_country_id FOREIGN KEY (country_id) REFERENCES countries(id);

-- Fill country id in infectious_cases_norm
UPDATE infectious_cases_norm i, countries c  
SET i.country_id = c.id WHERE c.code = i.code;

-- Remove colums entity end code from infectious_cases_norm
ALTER TABLE infectious_cases_norm
DROP COLUMN entity,
DROP COLUMN code;


-- ----Task #3----
-- Analize data
SELECT id, MAX(number_rabies) AS max_value, MIN(number_rabies) AS min_value, 
AVG(number_rabies) AS average_value FROM infectious_cases_norm
WHERE number_rabies IS NOT NULL AND number_rabies <> ''
GROUP BY id
ORDER BY average_value DESC
LIMIT 10;


-- ----Task #4----
-- Add start_date, cur_date, subtract_year in infectious_cases_norm 
ALTER TABLE infectious_cases_norm 
ADD COLUMN start_date DATE NULL AFTER year,
ADD COLUMN cur_date DATE NULL AFTER start_date,
ADD COLUMN subtract_year INT NULL AFTER cur_date;

-- Create function to calculate start_date
DROP FUNCTION IF EXISTS fn_start_date;

DELIMITER //

CREATE FUNCTION fn_start_date(year INT)
RETURNS DATE
DETERMINISTIC 
NO SQL
BEGIN
    DECLARE result DATE;
    SET result = MAKEDATE(year, 1);
    RETURN result;
END //

DELIMITER ;

-- Create function to calculate cur_date
DROP FUNCTION IF EXISTS fn_cur_date;

DELIMITER //

CREATE FUNCTION fn_cur_date()
RETURNS DATE
DETERMINISTIC 
NO SQL
BEGIN
    DECLARE result DATE;
    SET result = CURDATE();
    RETURN result;
END //

DELIMITER ;

-- Create function to calculate subtract_year
DROP FUNCTION IF EXISTS fn_subtract_year;

DELIMITER //

CREATE FUNCTION fn_subtract_year(cur_date DATE, start_date DATE)
RETURNS INT
DETERMINISTIC 
NO SQL
BEGIN
    DECLARE result INT;
    SET result = YEAR(cur_date) - YEAR(start_date);
    RETURN result;
END //

DELIMITER ;

-- Update table infectious_cases_norm with functions
UPDATE infectious_cases_norm
SET cur_date = fn_cur_date(),
start_date = fn_start_date(year),
subtract_year = fn_subtract_year(cur_date, start_date);


-- ----Task #5----
-- Create function fn_subtract_now_year
DROP FUNCTION IF EXISTS fn_subtract_now_year;

DELIMITER //

CREATE FUNCTION fn_subtract_now_year(year INT)
RETURNS INT
DETERMINISTIC 
NO SQL
BEGIN
    DECLARE result INT;
    SET result = YEAR(CURDATE()) - year;
    RETURN result;
END //

DELIMITER ;

SELECT fn_subtract_now_year(1984); -- Result 40 years

-- Create function fn_calc_illnesses_per_period
DROP FUNCTION IF EXISTS fn_calc_illnesses_per_period;

DELIMITER //

CREATE FUNCTION fn_calc_illnesses_per_period(num_illnesses_per_year DOUBLE, period INT)
RETURNS DOUBLE
DETERMINISTIC 
NO SQL
BEGIN
    DECLARE result DOUBLE;
    SET result = num_illnesses_per_year / period;
    RETURN result;
END //

DELIMITER ;

SELECT fn_calc_illnesses_per_period(20000, 4); -- Result 5000 illnesses
