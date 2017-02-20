DROP TABLE IF EXISTS multimodal_routing.links CASCADE;

CREATE TABLE multimodal_routing.links
(
link_id long,
begin_node_id long,
end_node_id long,
begin_angle double precision,
end_angle double precision,
street_length double precision,
osm_name string,
osm_class string,
osm_way_id long,
startX double precision,
startY double precision,
endX double precision,
endY double precision,
osm_changeset long,

  PRIMARY KEY (begin_node_id, end_node_id)
)
WITH
(
OIDS=FALSE
);


--------------------------------
------------Comments------------
--------------------------------
COMMENT ON TABLE multimodal_routing.links IS 'road segments connecting two nodes';

COMMENT ON COLUMN multimodal_routing.links.link_id IS 'unique identifier for each link'
COMMENT ON COLUMN multimodal_routing.links.begin_node_id IS 'the first node this link attaches to';
COMMENT ON COLUMN multimodal_routing.links.end_node_id IS 'the second node this link attaches to';
COMMENT ON COLUMN multimodal_routing.links.begin_angle IS 'angle of the link viewed from the begin node; an angle of 0 is a link pointing due north and it increases CCW';
COMMENT ON COLUMN multimodal_routing.links.end_angle IS 'angle of the link viewed from the end node; an angle of 180 is a link pointing due north and it increases CCW';
COMMENT ON COLUMN multimodal_routing.links.street_length IS 'the length of the link in meters';
COMMENT ON COLUMN multimodal_routing.osm_name IS 'the name of the street';
COMMENT ON COLUMN multimodal_routing.osm_class IS 'the type of street (highway, residential, etc.)';
