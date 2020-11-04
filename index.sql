-- Ref: https://github.com/nelhage/reptyr
-- Ref: https://github.com/pthom/northwind_psql

EXPLAIN (ANALYSE ON) SELECT * FROM products WHERE unit_price >20;
EXPLAIN (ANALYSE ON, BUFFERS ON) SELECT * FROM products WHERE unit_price >20;

SELECT generate_series(1,10);

CREATE TABLE t1(c1 int);
INSERT INTO t1 (select generate_series(1, 1000));
SELECT count(1) FROM t1;

EXPLAIN SELECT * FROM t1;

-- CREATE INDEX
-- 1. STEP
-- 2. STEP
CREATE INDEX ON t1(c1); -- t1_c1_idx
CREATE INDEX t1_c1_index ON t1 USING  btree(c1);
CREATE INDEX CONCURRENTLY t1_c1_index ON t1 USING btree(c1);

EXPLAIN SELECT * FROM t1 WHERE c1 <100;
-- Index Only Scan using t1_c1_index on t1  (cost=0.28..4.21 rows=99 width=4)
-- Index Cond: (c1 < 100)

SELECT * FROM pg_catalog.pg_am; -- all installed index

/*
+----+------+--------------------+------+
|oid |amname|amhandler           |amtype|
+----+------+--------------------+------+
|2   |heap  |heap_tableam_handler|t     |
|403 |btree |bthandler           |i     |
|405 |hash  |hashhandler         |i     |
|783 |gist  |gisthandler         |i     |
|2742|gin   |ginhandler          |i     |
|4000|spgist|spghandler          |i     |
|3580|brin  |brinhandler         |i     |
+----+------+--------------------+------+
*/

EXPLAIN SELECT * FROM t1 WHERE c1 > 900;
-- Index Only Scan using t1_c1_index on t1  (cost=0.28..4.22 rows=100 width=4)
--   Index Cond: (c1 > 900)

INSERT INTO t1 (SELECT  generate_series(1001, 1000000));

EXPLAIN SELECT * FROM t1 WHERE c1 > 900;
-- Index Only Scan using t1_c1_index on t1  (cost=0.42..2294.78 rows=88500 width=4)
--  Index Cond: (c1 > 900)

EXPLAIN SELECT * FROM t1 WHERE c1 > 900;
-- Seq Scan on t1  (cost=0.00..16925.00 rows=999124 width=4)
--  Filter: (c1 > 900)

CREATE INDEX t1_c1_2_idx ON t1 (c1 ASC); -- ASC Ordered
CREATE INDEX t1_c1_3_idx ON t1 (c1 DESC);
CREATE INDEX t1_c1_4_idx ON t1 (c1 NULLS LAST);
CREATE INDEX t1_c1_5_idx ON t1 (c1 NULLS FIRST);
CREATE UNIQUE INDEX ON t1(c1);

CREATE TABLE t2(c1 int);
INSERT INTO t2 VALUES (1),(1);
CREATE UNIQUE INDEX ON t2(c1);
-- could not create unique index "t2_c1_idx"
-- Detail: Key (c1)=(1) is duplicated.

DROP INDEX CONCURRENTLY t1_c1_index;
DROP INDEX t1_c1_2_idx;
DROP INDEX t1_c1_3_idx;
DROP INDEX t1_c1_4_idx;
DROP INDEX t1_c1_5_idx;

REINDEX INDEX t1_c1_2_idx;
REINDEX INDEX CONCURRENTLY t1_c1_2_idx;

-- btree -> =, <, <=, >, =>, between, like
EXPLAIN SELECT * FROM products WHERE product_name like '%a';

CREATE INDEX ON t1 USING hash(c1);

SELECT pg_size_pretty(pg_relation_size('t1'));
/*
Table Space
+--------------+
|pg_size_pretty|
+--------------+
|35 MB         |
+--------------+
*/

SELECT pg_size_pretty(pg_relation_size('t1_c1_idx'));
/*
Index Space
+--------------+
|pg_size_pretty|
+--------------+
|21 MB         |
+--------------+
*/

SELECT pg_size_pretty(pg_total_relation_size('t1'));
/*
Total Space
+--------------+
|pg_size_pretty|
+--------------+
|131 MB        |
+--------------+
*/

EXPLAIN  SELECT * FROM t1 WHERE c1 <100;
/*
+-------------------------------------------------------------------------+
|QUERY PLAN                                                               |
+-------------------------------------------------------------------------+
|Index Only Scan using t1_c1_idx1 on t1  (cost=0.42..4.30 rows=96 width=4)|
|  Index Cond: (c1 < 100)                                                 |
+-------------------------------------------------------------------------+

*/

CREATE INDEX ON t1(c1) WHERE c1 <100; -- partial index
EXPLAIN  SELECT * FROM t1 WHERE c1 <100;

/*
+-------------------------------------------------------------------------+
|QUERY PLAN                                                               |
+-------------------------------------------------------------------------+
|Index Only Scan using t1_c1_idx1 on t1  (cost=0.42..4.30 rows=96 width=4)|
|  Index Cond: (c1 < 100)                                                 |
+-------------------------------------------------------------------------+
*/

SELECT pg_size_pretty(pg_relation_size('t1_c1_idx1'));
/*
+--------------+
|pg_size_pretty|
+--------------+
|21 MB         |
+--------------+
*/

SELECT pg_size_pretty(pg_total_relation_size('t1'));
/*
+--------------+
|pg_size_pretty|
+--------------+
|131 MB        |
+--------------+
*/

CREATE TABLE student(c1 int, c2 varchar(30));
INSERT INTO student VALUES
                           (1, 'Ibrahim'),
                           (2, 'Filiz'),
                           (3, 'Ozgun'),
                           (4, 'Dorukan');

CREATE INDEX student_c2_index ON student(c2);

SELECT upper(c2) FROM student; -- Encoding-UTF8
/*
+-------+
|upper  |
+-------+
|IBRAHİM|
|FİLİZ  |
|OZGUN  |
|DORUKAN|
+-------+
*/

EXPLAIN SELECT * FROM student WHERE upper(c2) ='DORUKAN';
--  1 row retrieved starting from 1 in 77 ms (execution: 15 ms, fetching: 62 ms)

CREATE INDEX student_c2_upper_index ON student (upper(c2));
EXPLAIN SELECT * FROM student WHERE upper(c2) ='DORUKAN';
-- 1 row retrieved starting from 1 in 27 ms (execution: 8 ms, fetching: 19 ms)

SELECT * FROM pg_database;
SELECT * FROM pg_stats WHERE tablename='t1';

VACUUM t1;
EXPLAIN (ANALYSE ON, BUFFERS ON, COSTS ON) SELECT * FROM t1 WHERE c1 <100;
SELECT * FROM pg_class WHERE relname='t1';
/*
+-----------------------------------------------------------------------------------------------------------+
|QUERY PLAN                                                                                                 |
+-----------------------------------------------------------------------------------------------------------+
|Seq Scan on t1  (cost=0.00..14425.00 rows=1000000 width=4) (actual time=0.007..73.133 rows=1000000 loops=1)|
|  Buffers: shared hit=4425                                                                                 |
|Planning Time: 0.142 ms                                                                                    |
|Execution Time: 117.798 ms                                                                                 |
+-----------------------------------------------------------------------------------------------------------+
*/