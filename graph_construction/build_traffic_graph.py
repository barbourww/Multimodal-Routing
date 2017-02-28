import networkx as nx
from tv_edge import TVEdge
import csv
import datetime as dt

# get nodes
# nodes_file = '/Users/wbarbour1/Downloads/nodes.csv'
# nodes_file = '/Users/wbarbour1/Google Drive/Classes/CEE_418/final_project/selected_nodes.csv'
nodes_file = '/sata_ssd1/multimodal_graph/selected_nodes.csv'
with open(nodes_file, 'r') as nf:
    take_cols = [(0, long), (2, int), (3, int), (5, float), (6, float), (10, int)]
    # if using selected nodes taken from QGIS, the (X, Y) coordinates will be added at the beginning of the columns
    # activate the following to shift the indices of columns to take from the file and use the ';' delimiter
    if True:
        take_cols = [(tc[0] + 2, tc[1]) for tc in take_cols]
        reader = csv.reader(nf, delimiter=';')
    else:
        reader = csv.reader(nf, delimiter=',')
    nodes_h = reader.next()
    nodes_h = [nodes_h[c] for c, ty in take_cols]
    nodes = [[ty(line[c]) for c, ty in take_cols] for line in reader]
    print len(nodes), "nodes loaded."

# get links
# links_file = '/Users/wbarbour1/Downloads/links.csv'
links_file = '/sata_ssd1/multimodal_graph/links.csv'
with open(links_file, 'r') as lf:
    reader = csv.reader(lf, delimiter=',')
    take_cols = [(1, long), (2, long), (5, float), (6, str), (7, str),
                 (9, float), (10, float), (11, float), (12, float)]
    links_h = reader.next()
    links_h = [links_h[c] for c, ty in take_cols]
    links = [[ty(line[c]) for c, ty in take_cols] for line in reader]
    print len(links), "links loaded."

year = '2013'
day0 = dt.datetime.strptime('01/01/%s 00:00:00' % year, '%m/%d/%Y %H:%M:%S').date()
dayf = dt.datetime.strptime('03/31/%s 23:00:00' % year, '%m/%d/%Y %H:%M:%S').date()


G = nx.DiGraph(name='Multimodal Routing Graph')

for n in nodes:
    G.add_node(n=n[0], attr_dict=dict(zip(nodes_h[1:], n[1:])))
print "Nodes added.\n"
print nx.info(G), '\n'

# hourly_data_file = '/Users/wbarbour1/Downloads/'
hourly_data_file = '/sata_ssd1/multimodal_graph/travel_times_%s.csv' % year
with open(hourly_data_file, 'r') as hf:
    reader = csv.reader(hf, delimiter=',')
    take_cols = [(0, long), (1, long), (2, str), (3, float)]
    hourly_h = reader.next()
    hourly_h = [hourly_h[c] for c, ty in take_cols]
    hourly = [[ty(line[c]) for c, ty in take_cols] for line in reader]
    print len(hourly), "hourly records loaded."
    hourly = [h for h in hourly if h[0] and h[1] in G.nodes()]
    print len(hourly), "hourly records retained."

for l in links:
    if l[0] and l[1] in G.nodes():
        d = {day0 + dt.timedelta(days=i): {h: 10. for h in range(0, 24)} for i in range((dayf - day0).days)}
        tve = TVEdge(data_map=d, tv_type='day:hour')
        G.add_edge(u=l[0], v=l[1], attr_dict=dict(zip(links_h[2:], l[2:])), tve=tve)
print "Links added.\n"
print nx.info(G), '\n'

# graph_dest_path = '/Users/wbarbour1/Downloads/graph_test1.gpkl'
graph_dest_path = '/sata_ssd1/multimodal_graph/graph_test_full.gpkl'
nx.write_gpickle(G, graph_dest_path)
print "Graph written to file:", graph_dest_path
