DROP TABLE IF EXISTS travel_times.link_travel_times CASCADE;

CREATE TABLE travel_times.link_travel_times
(
  begin_node_id bigint,
  end_node_id bigint,
  date_time timestamp without time zone,
  travel_time double precision,
  num_trips integer,

  PRIMARY KEY (begin_node_id, end_node_id, date_time)
)
WITH
(
OIDS=FALSE
);


--------------------------------
------------Comments------------
--------------------------------
COMMENT ON TABLE travel_times.link_travel_times IS 'estimated travel times of included links';

COMMENT ON COLUMN travel_times.link_travel_times.begin_node_id IS 'the begin_node_id of the relevant link';
COMMENT ON COLUMN travel_times.link_travel_times.end_node_id IS 'the end_node_id of the relevant link';
COMMENT ON COLUMN travel_times.link_travel_times.date_time IS 'the hour in which the given traffic estimate occurs, beginning of hour';
COMMENT ON COLUMN travel_times.link_travel_times.travel_time IS 'estimated amount of time for a vehicle to travel over this link';
COMMENT ON COLUMN travel_times.link_travel_times.num_trips IS 'estimated number of taxis that drove over this link during the hour';


-----------------------------------------------
------------Create Partition Tables------------
-----------------------------------------------

-----------------
--2010 partitions
-----------------
CREATE TABLE travel_times.link_travel_times_y2010m01
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '01-01-2010'::date AND date_time < '02-01-2010'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2010m02
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '02-01-2010'::date AND date_time < '03-01-2010'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2010m03
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '03-01-2010'::date AND date_time < '04-01-2010'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2010m04
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '04-01-2010'::date AND date_time < '05-01-2010'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2010m05
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '05-01-2010'::date AND date_time < '06-01-2010'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2010m06
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '06-01-2010'::date AND date_time < '07-01-2010'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2010m07
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '07-01-2010'::date AND date_time < '08-01-2010'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2010m08
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '08-01-2010'::date AND date_time < '09-01-2010'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2010m09
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '09-01-2010'::date AND date_time < '10-01-2010'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2010m10
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '10-01-2010'::date AND date_time < '11-01-2010'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2010m11
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '11-01-2010'::date AND date_time < '12-01-2010'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2010m12
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '12-01-2010'::date AND date_time < '01-01-2011'::date)
)
INHERITS (travel_times.link_travel_times);


-----------------
--2011 partitions
-----------------
CREATE TABLE travel_times.link_travel_times_y2011m01
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '01-01-2011'::date AND date_time < '02-01-2011'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2011m02
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '02-01-2011'::date AND date_time < '03-01-2011'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2011m03
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '03-01-2011'::date AND date_time < '04-01-2011'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2011m04
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '04-01-2011'::date AND date_time < '05-01-2011'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2011m05
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '05-01-2011'::date AND date_time < '06-01-2011'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2011m06
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '06-01-2011'::date AND date_time < '07-01-2011'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2011m07
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '07-01-2011'::date AND date_time < '08-01-2011'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2011m08
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '08-01-2011'::date AND date_time < '09-01-2011'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2011m09
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '09-01-2011'::date AND date_time < '10-01-2011'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2011m10
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '10-01-2011'::date AND date_time < '11-01-2011'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2011m11
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '11-01-2011'::date AND date_time < '12-01-2011'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2011m12
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '12-01-2011'::date AND date_time < '01-01-2012'::date)
)
INHERITS (travel_times.link_travel_times);



-----------------
--2012 partitions
-----------------
CREATE TABLE travel_times.link_travel_times_y2012m01
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '01-01-2012'::date AND date_time < '02-01-2012'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2012m02
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '02-01-2012'::date AND date_time < '03-01-2012'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2012m03
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '03-01-2012'::date AND date_time < '04-01-2012'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2012m04
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '04-01-2012'::date AND date_time < '05-01-2012'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2012m05
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '05-01-2012'::date AND date_time < '06-01-2012'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2012m06
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '06-01-2012'::date AND date_time < '07-01-2012'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2012m07
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '07-01-2012'::date AND date_time < '08-01-2012'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2012m08
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '08-01-2012'::date AND date_time < '09-01-2012'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2012m09
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '09-01-2012'::date AND date_time < '10-01-2012'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2012m10
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '10-01-2012'::date AND date_time < '11-01-2012'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2012m11
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '11-01-2012'::date AND date_time < '12-01-2012'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2012m12
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '12-01-2012'::date AND date_time < '01-01-2013'::date)
)
INHERITS (travel_times.link_travel_times);



-----------------
--2013 partitions
-----------------
CREATE TABLE travel_times.link_travel_times_y2013m01
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '01-01-2013'::date AND date_time < '02-01-2013'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2013m02
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '02-01-2013'::date AND date_time < '03-01-2013'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2013m03
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '03-01-2013'::date AND date_time < '04-01-2013'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2013m04
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '04-01-2013'::date AND date_time < '05-01-2013'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2013m05
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '05-01-2013'::date AND date_time < '06-01-2013'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2013m06
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '06-01-2013'::date AND date_time < '07-01-2013'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2013m07
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '07-01-2013'::date AND date_time < '08-01-2013'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2013m08
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '08-01-2013'::date AND date_time < '09-01-2013'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2013m09
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '09-01-2013'::date AND date_time < '10-01-2013'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2013m10
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '10-01-2013'::date AND date_time < '11-01-2013'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2013m11
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '11-01-2013'::date AND date_time < '12-01-2013'::date)
)
INHERITS (travel_times.link_travel_times);

CREATE TABLE travel_times.link_travel_times_y2013m12
(
PRIMARY KEY (begin_node_id, end_node_id, date_time),
CHECK (date_time >= '12-01-2013'::date AND date_time < '01-01-2018'::date)
)
INHERITS (travel_times.link_travel_times);



--------------------------------------
------------Create Indexes------------
--------------------------------------

------
--2010
------
CREATE INDEX link_travel_times_y2010m01_indx ON travel_times.link_travel_times_y2010m01 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2010m02_indx ON travel_times.link_travel_times_y2010m02 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2010m03_indx ON travel_times.link_travel_times_y2010m03 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2010m04_indx ON travel_times.link_travel_times_y2010m04 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2010m05_indx ON travel_times.link_travel_times_y2010m05 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2010m06_indx ON travel_times.link_travel_times_y2010m06 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2010m07_indx ON travel_times.link_travel_times_y2010m07 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2010m08_indx ON travel_times.link_travel_times_y2010m08 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2010m09_indx ON travel_times.link_travel_times_y2010m09 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2010m10_indx ON travel_times.link_travel_times_y2010m10 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2010m11_indx ON travel_times.link_travel_times_y2010m11 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2010m12_indx ON travel_times.link_travel_times_y2010m12 
(begin_node_id, end_node_id, date_time);

------
--2011
------
CREATE INDEX link_travel_times_y2011m01_indx ON travel_times.link_travel_times_y2011m01 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2011m02_indx ON travel_times.link_travel_times_y2011m02 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2011m03_indx ON travel_times.link_travel_times_y2011m03 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2011m04_indx ON travel_times.link_travel_times_y2011m04 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2011m05_indx ON travel_times.link_travel_times_y2011m05 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2011m06_indx ON travel_times.link_travel_times_y2011m06 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2011m07_indx ON travel_times.link_travel_times_y2011m07 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2011m08_indx ON travel_times.link_travel_times_y2011m08 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2011m09_indx ON travel_times.link_travel_times_y2011m09 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2011m10_indx ON travel_times.link_travel_times_y2011m10 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2011m11_indx ON travel_times.link_travel_times_y2011m11 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2011m12_indx ON travel_times.link_travel_times_y2011m12 
(begin_node_id, end_node_id, date_time);

------
--2012
------
CREATE INDEX link_travel_times_y2012m01_indx ON travel_times.link_travel_times_y2012m01 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2012m02_indx ON travel_times.link_travel_times_y2012m02 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2012m03_indx ON travel_times.link_travel_times_y2012m03 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2012m04_indx ON travel_times.link_travel_times_y2012m04 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2012m05_indx ON travel_times.link_travel_times_y2012m05 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2012m06_indx ON travel_times.link_travel_times_y2012m06 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2012m07_indx ON travel_times.link_travel_times_y2012m07 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2012m08_indx ON travel_times.link_travel_times_y2012m08 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2012m09_indx ON travel_times.link_travel_times_y2012m09 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2012m10_indx ON travel_times.link_travel_times_y2012m10 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2012m11_indx ON travel_times.link_travel_times_y2012m11 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2012m12_indx ON travel_times.link_travel_times_y2012m12 
(begin_node_id, end_node_id, date_time);

------
--2013
------
CREATE INDEX link_travel_times_y2013m01_indx ON travel_times.link_travel_times_y2013m01 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2013m02_indx ON travel_times.link_travel_times_y2013m02 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2013m03_indx ON travel_times.link_travel_times_y2013m03 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2013m04_indx ON travel_times.link_travel_times_y2013m04 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2013m05_indx ON travel_times.link_travel_times_y2013m05 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2013m06_indx ON travel_times.link_travel_times_y2013m06 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2013m07_indx ON travel_times.link_travel_times_y2013m07 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2013m08_indx ON travel_times.link_travel_times_y2013m08 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2013m09_indx ON travel_times.link_travel_times_y2013m09 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2013m10_indx ON travel_times.link_travel_times_y2013m10 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2013m11_indx ON travel_times.link_travel_times_y2013m11 
(begin_node_id, end_node_id, date_time);
CREATE INDEX link_travel_times_y2013m12_indx ON travel_times.link_travel_times_y2013m12 
(begin_node_id, end_node_id, date_time);



-----------------------------------------------
------------Create Trigger Function------------
-----------------------------------------------
CREATE OR REPLACE FUNCTION travel_times.link_travel_times_insert_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.date_time >= '01-01-2010'::date AND NEW.date_time < '02-01-2010'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2010m01 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '02-01-2010'::date AND NEW.date_time < '03-01-2010'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2010m02 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '03-01-2010'::date AND NEW.date_time < '04-01-2010'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2010m03 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '04-01-2010'::date AND NEW.date_time < '05-01-2010'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2010m04 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '05-01-2010'::date AND NEW.date_time < '06-01-2010'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2010m05 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '06-01-2010'::date AND NEW.date_time < '07-01-2010'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2010m06 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '07-01-2010'::date AND NEW.date_time < '08-01-2010'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2010m07 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '08-01-2010'::date AND NEW.date_time < '09-01-2010'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2010m08 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '09-01-2010'::date AND NEW.date_time < '10-01-2010'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2010m09 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '10-01-2010'::date AND NEW.date_time < '11-01-2010'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2010m10 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '11-01-2010'::date AND NEW.date_time < '12-01-2010'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2010m11 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '12-01-2010'::date AND NEW.date_time < '01-01-2011'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2010m12 VALUES (NEW.*);

	ELSIF (NEW.date_time >= '01-01-2011'::date AND NEW.date_time < '02-01-2011'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2011m01 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '02-01-2011'::date AND NEW.date_time < '03-01-2011'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2011m02 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '03-01-2011'::date AND NEW.date_time < '04-01-2011'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2011m03 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '04-01-2011'::date AND NEW.date_time < '05-01-2011'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2011m04 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '05-01-2011'::date AND NEW.date_time < '06-01-2011'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2011m05 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '06-01-2011'::date AND NEW.date_time < '07-01-2011'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2011m06 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '07-01-2011'::date AND NEW.date_time < '08-01-2011'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2011m07 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '08-01-2011'::date AND NEW.date_time < '09-01-2011'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2011m08 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '09-01-2011'::date AND NEW.date_time < '10-01-2011'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2011m09 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '10-01-2011'::date AND NEW.date_time < '11-01-2011'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2011m10 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '11-01-2011'::date AND NEW.date_time < '12-01-2011'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2011m11 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '12-01-2011'::date AND NEW.date_time < '01-01-2012'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2011m12 VALUES (NEW.*);

	ELSIF (NEW.date_time >= '01-01-2012'::date AND NEW.date_time < '02-01-2012'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2012m01 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '02-01-2012'::date AND NEW.date_time < '03-01-2012'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2012m02 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '03-01-2012'::date AND NEW.date_time < '04-01-2012'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2012m03 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '04-01-2012'::date AND NEW.date_time < '05-01-2012'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2012m04 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '05-01-2012'::date AND NEW.date_time < '06-01-2012'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2012m05 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '06-01-2012'::date AND NEW.date_time < '07-01-2012'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2012m06 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '07-01-2012'::date AND NEW.date_time < '08-01-2012'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2012m07 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '08-01-2012'::date AND NEW.date_time < '09-01-2012'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2012m08 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '09-01-2012'::date AND NEW.date_time < '10-01-2012'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2012m09 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '10-01-2012'::date AND NEW.date_time < '11-01-2012'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2012m10 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '11-01-2012'::date AND NEW.date_time < '12-01-2012'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2012m11 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '12-01-2012'::date AND NEW.date_time < '01-01-2013'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2012m12 VALUES (NEW.*);

	ELSIF (NEW.date_time >= '01-01-2013'::date AND NEW.date_time < '02-01-2013'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2013m01 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '02-01-2013'::date AND NEW.date_time < '03-01-2013'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2013m02 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '03-01-2013'::date AND NEW.date_time < '04-01-2013'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2013m03 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '04-01-2013'::date AND NEW.date_time < '05-01-2013'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2013m04 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '05-01-2013'::date AND NEW.date_time < '06-01-2013'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2013m05 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '06-01-2013'::date AND NEW.date_time < '07-01-2013'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2013m06 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '07-01-2013'::date AND NEW.date_time < '08-01-2013'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2013m07 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '08-01-2013'::date AND NEW.date_time < '09-01-2013'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2013m08 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '09-01-2013'::date AND NEW.date_time < '10-01-2013'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2013m09 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '10-01-2013'::date AND NEW.date_time < '11-01-2013'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2013m10 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '11-01-2013'::date AND NEW.date_time < '12-01-2013'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2013m11 VALUES (NEW.*);
	ELSIF (NEW.date_time >= '12-01-2013'::date AND NEW.date_time < '01-01-2018'::date)
	THEN INSERT INTO travel_times.link_travel_times_y2013m12 VALUES (NEW.*);

	ELSE
	RAISE EXCEPTION 'Date out of range. May need to alter trigger function and add new partitions.';
	END IF;
RETURN NULL;
END;
$$
LANGUAGE plpgsql;



---------------------------------------------
------------Create Insert Trigger------------
---------------------------------------------
CREATE TRIGGER insert_link_travel_times_trigger
BEFORE INSERT ON travel_times.link_travel_times
FOR EACH ROW EXECUTE PROCEDURE travel_times.link_travel_times_insert_trigger_func();
