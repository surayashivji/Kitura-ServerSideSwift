-- Indexing for Performance, makes searches faster

-- without it mysql would have to look at every single row for a WHERE clause
-- indexing = mark certain fields as being important for searching
-- if u say the "user" field in "post" table should be indexed, mysql will store all users in a special cache
-- that can be searched more efficientlycompar
-- cost of index: everytime u add/update/delete rows mysql has to update its indexes (but we read data more than write usually so its worth it most of time)

-- create test table, fill with random numbers
CREATE TABLE `test_numbers`(`number` INT);
INSERT INTO `test_numbers` VALUES (RAND() * 1000000); -- RAND() is random between 0 & 1, overall is numbers between 0 & 1 million
-- select pulls out numbers in the table and multiples them by RAND() to make new #'s
-- insert takes the value from above and puts them in table
-- do this a bunch of times to get ~8 mil --> progressively gets smaller since it multiples current values with value <= 1
INSERT IGNORE INTO `test_numbers` SELECT `number` * RAND() FROM `test_numbers`;
SELECT COUNT(*) FROM `test_numbers` WHERE `number` > 1000; -- only about a million (out of 8) are > 1000
-- above select statement: took about 6 seconds -- (we're only doing one int comparison, and reading data)
-- above, mysql is performing a full table scan (goes over every row to do comparison)
-- if we add an index for the `number` field, mysql will store them ahead of time in an optimized way

-- read all the number values into an index (value cache)
-- took ~ 24 seconds but that only happens once
ALTER TABLE `test_numbers` ADD INDEX (`number`);

-- run same read query again
-- took 0.34 seconds!!!!! (down from 6 seconds)
SELECT COUNT(*) FROM `test_numbers` WHERE `number` > 1000;

-- you can index any data type
-- over indexing is worth than not having an index


