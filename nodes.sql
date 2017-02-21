DROP TABLE IF EXISTS network_topo.nodes CASCADE;

CREATE TABLE network_topo.nodes
(
node_id bigint,
is_complete boolean,
num_in_links int,
num_out_links int,
osm_traffic_controller text,
xcoord double precision,
ycoord double precision,
osm_changeset bigint,
birth_timestamp bigint,
death_timestamp bigint,
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
COMMENT ON TABLE network_topo.nodes IS 'information for included nodes';

COMMENT ON COLUMN network_topo.nodes.node_id IS 'a unique identifier of each node';
COMMENT ON COLUMN network_topo.nodes.xcoord IS 'the longitude of the node';
COMMENT ON COLUMN network_topo.nodes.ycoord IS 'the latitude of the node';
