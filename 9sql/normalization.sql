-- normalize for efficiency & organization

-- BAD --
CREATE TABLE `purchases` 
	(`id` INT PRIMARY KEY AUTO_INCREMENT,    
	`item` VARCHAR(255),    
	`customer_name` VARCHAR(255),    
	`address` VARCHAR(255),    
	`city` VARCHAR(255),    
	`zip` VARCHAR(255),    
	`country` VARCHAR(255) 
	);
-- if same customer is in `purchases` table, its same data repeating
-- hard to update values, split it into different tables

-- `items` table has ID and title, `purchases` table would hold the items ID's (Easier to update)
-- `customers` table has ID and customer, `purchases` table would hold purchases ID's 
	-- IE query: queries such as “show all purchases by customer 234 
-- `delivery_address` table with customer ID field (points to customer table) and their address info
	-- id number of delivery_address would be stored in purchases so customers can have multiple addresses

CREATE TABLE `purchases` 
	(`id` INT PRIMARY KEY AUTO_INCREMENT,
	`item_id` INT,    
	`customer_id` INT,    
	`delivery_address_id` INT
	);

CREATE TABLE `items` 
	(`id` INT PRIMARY KEY AUTO_INCREMENT,    
	`name` VARCHAR(255) 
	);

CREATE TABLE `customers` 
	(`id` INT PRIMARY KEY AUTO_INCREMENT,    
	`name` VARCHAR(255) 
	);

CREATE TABLE `delivery_addresses` 
	(`id` INT PRIMARY KEY AUTO_INCREMENT,
	`customer_id` INT,
	`address` VARCHAR(255),
	`city` VARCHAR(255),
	`zip` VARCHAR(255),
	`country` VARCHAR(255) 
	);

-- test data

INSERT INTO `purchases` VALUES (1, 1, 1, 1);
INSERT INTO `items` VALUES (1, "Data Structures and Algorithms");
INSERT INTO `customers` VALUES (1, "Tom Smith"); 
INSERT INTO `delivery_addresses` VALUES (1, 1, "Address", "City", "Zip", "Country");

-- reading back normalized data
-- query multiple tables at once and tell mysql how data matches up


-- pulls out item_id, customer_id, and delivery_address_id from purchases
SELECT `item_id`, `customer_id`, `delivery_address_id` FROM `purchases` WHERE `id` = 1;

-- tell sql we want the name for the item_id given from the `items` table
-- selecting item_id and name in same query so sql knows what to match up from where clause
SELECT `item_id`, `name`, `customer_id`, `delivery_address` 
FROM `purchases`, `items`
WHERE `purchases`.`id` = 1 
AND `items`.`id` = `item_id`;
-- rewrite query with aliases to make things more readable and easier to write
SELECT `item_id`, `name`, `customer_id`, `delivery_address` 
FROM `purchases` p, `items` i 
WHERE p.`id` = 1 
AND i.`id` = `item_id`;

-- we have name field in items and customers, use aliases to be specific
SELECT `item_id`, i.`name`, `customer_id`, c.`name`, `delivery_address` 
FROM `purchases` p, `items` i, `customers` c 
WHERE p.`id` = 1 
AND i.`id` = `item_id` 
AND c.`id` = `customer_id`;

-- add delivery info, going across 4 tables
SELECT `item_id`, i.`name`, p.`customer_id`, c.`name`, `delivery_address`, d.`address`, d.`city`, d.`zip`, d.`country` 
FROM `purchases` p, `items` i, `customers` c, `delivery_addresses` d 
WHERE p.`id` = 1 
AND i.`id` = `item_id` 
AND c.`id` = p.`customer_id` 
AND d.`id` = p.`delivery_address`;



-- normalization is computationally expensive
-- sometimes u should just denoramlize (intentionally replicate data) if something is performance critical


