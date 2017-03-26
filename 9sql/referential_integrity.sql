-- when using normalization, an id in one table references an entire row of data in a different table
	-- problem with this: what happens when you delete data?

-- foreign key = SQL's way of linking the data explicitly so that if one item goes anything that references it also goes
-- foreign key = field in one table that points to primary key in another table

-- "reflecting of changes" (ie making sure deleting one thing deletes its reference) = cascading in SQL

-- update microblog posts table so that if a user is deleted all posts by that user are also deleted
ALTER TABLE `posts` ADD CONSTRAINT FOREIGN KEY (`user`)
REFERENCES `users`(`id`) ON UPDATE CASCADE ON DELETE CASCADE;


-- deleting user --> posts deleted too