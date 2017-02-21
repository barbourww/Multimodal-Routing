DROP TABLE IF EXISTS network_topo.links CASCADE;

CREATE TABLE network_topo.links
(
link_id bigint,
begin_node_id bigint,
end_node_id bigint,
begin_angle double precision,
end_angle double precision,
street_length double precision,
osm_name text,
osm_class text,
osm_way_id bigint,
startX double precision,
startY double precision,
endX double precision,
endY double precision,
osm_changeset bigint,
birth_timestamp bigint,
death_timestamp bigint,

  PRIMARY KEY (begin_node_id, end_node_id)
)
WITH
(
OIDS=FALSE
);


--------------------------------
------------Comments------------
--------------------------------
COMMENT ON TABLE network_topo.links IS 'road segments connecting two nodes';

COMMENT ON COLUMN network_topo.links.link_id IS 'unique identifier for each link';
COMMENT ON COLUMN network_topo.links.begin_node_id IS 'the first node this link attaches to';
COMMENT ON COLUMN network_topo.links.end_node_id IS 'the second node this link attaches to';
COMMENT ON COLUMN network_topo.links.begin_angle IS 'angle of the link viewed from the begin node; an angle of 0 is a link pointing due north and it increases CCW';
COMMENT ON COLUMN network_topo.links.end_angle IS 'angle of the link viewed from the end node; an angle of 180 is a link pointing due north and it increases CCW';
COMMENT ON COLUMN network_topo.links.street_length IS 'the length of the link in meters';
COMMENT ON COLUMN network_topo.links.osm_name IS 'the name of the street';
COMMENT ON COLUMN network_topo.links.osm_class IS 'the type of street (highway, residential, etc.)';
