-- transactions for consistency

-- problem: when queries depend on each other (ie do query 1, 2, then 3) and one fails, then db is in inconsistent state
-- once you start a transaction, you can run as many queries as you'd like, but they only have a 
-- permanent effect if you commit the entire transaction at the end 
-- if things are going bad in the middle of the transaction you can rollback the transaction (reverts all changes you would've made)

-- mysql guarantees that your transactions are 'atomic' ie they are all or nothing
-- either all queries in transaction will be executed successfully or none

-- starts a transaction
START TRANSACTION

-- makes all queries from a transaction permanent
COMMIT

-- erases all queries from a transaction as if it never happened
ROLLBACK


-- any select statements u make inside transcation, sql shows it as if transaction has gone through even though it hasnt been comitted


-- IE for microblog 7 data
-- runs same SELECT 3 times
-- first time: see all posts, second time, see no posts (deleted), third time, see all posts bc transaction was rolledback
START TRANSACTION;
SELECT * FROM `posts`;
DELETE FROM `posts`;
SELECT * FROM `posts`;
ROLLBACK; 
SELECT * FROM `posts`;


-- use transactions eveywhere
-- they keep your data safe, consistent, and performs faster because mysql can bulk executes it writes

-- how to start a transaction in swift
-- tell mysql to stop autocomitting changes
try db.execute("SET autocommit=0;", [], connection)

-- then run as many queries as u want

-- rollback or commit in swift:
try db.execute("ROLLBACK;", [], connection)
try db.execute("COMMIT;", [], connection)

-- note - if u start transaction and don't commit before route ends it will be automatically rolled back
