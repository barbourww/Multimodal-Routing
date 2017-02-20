DROP TABLE IF EXISTS traveltimes.nodes CASCADE;

CREATE TABLE traveltimes.nodes
(
node_id long,
num_in_links int,
num_out_links int,
xcoord double precision,
ycoord double precision,
osm_changeset long,
grid_region_id integer,

  PRIMARY KEY (node_id)
)
WITH
(
OIDS=FALSE
);


--------------------------------
------------Comments------------
--------------------------------
COMMENT ON TABLE traveltimes.nodes IS 'information for included nodes';

COMMENT ON COLUMN node_id IS 'a unique identifier of each node';
COMMENT ON COLUMN traveltimes.nodes.xcoord IS 'the longitude of the node';
COMMENT ON COLUMN traveltimes.nodes.ycoord IS 'the latitude of the node';
