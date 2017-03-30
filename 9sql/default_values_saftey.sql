-- db fields have values like var/int but they can also be null
-- null is useless cuz its not safe and anything u compare it to will equate to null
-- mysql automatically assigns null to a field if u insert row without giving that field a value

-- two options to avoid having null in data
	-- 1 declare field as NOT NULL(value has to be specified or insert won't work)
	-- 2 provide default value in place of null 
-- should do both^

-- example

-- original create table for 0.sql for microblog7 project
CREATE TABLE `posts` 
	(`id` INT PRIMARY KEY AUTO_INCREMENT,    
	`user` VARCHAR(64),
	`message` VARCHAR(140),
	`parent` INT,
	`date` DATETIME 
	);

	-- id/user should be mandatory, but no default values make sense
	-- date should have default value for NOW(), and NOT NULL
	-- parent should have default value of 0 (so every post is new message unless specified otherwise), and NOT NULL

-- new table:
CREATE TABLE `posts` 
	(`id` INT PRIMARY KEY AUTO_INCREMENT,
	`user` VARCHAR(64) NOT NULL,
	`message` VARCHAR(140) NOT NULL,
	`parent` INT NOT NULL DEFAULT 0,
	`date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
	);

-- side notes
-- if SELECT query is slow, try putting EXPLAIN keyword before it in mysql monitor --
		-- this will ask mysql how it intends to search the data, what indexes will be used, how many rows to check etc

-- to see what character set table is using run SHOW TABLE STATUS and look under "Collation"
-- create tables with "utf8mb4" character set (as good as swift with unicode), all UTF-8 characters

-- how?
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- paste if after u create table
-- ie
CREATE TABLE `users` 
	(`id` VARCHAR(64) PRIMARY KEY,    
	`password` VARCHAR(128) NOT NULL,
	`salt` VARCHAR(128) NOT NULL
	)

CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
