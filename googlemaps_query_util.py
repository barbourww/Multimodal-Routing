import pytz
import traceback
import time
import multiprocessing
import os
from math import radians, cos, sin, sqrt, asin


class PrintLogTee(object):
    def __init__(self, *files):
        self.files = files

    def write(self, obj):
        for fl in self.files:
            fl.write(obj)
            fl.flush()  # If you want the output to be visible immediately

    def flush(self):
        for fl in self.files:
            fl.flush()


tzmap = {'p': 'US/Pacific', 'pst': 'US/Pacific', 'pdt': 'US/Pacific',
         'pacific': 'US/Pacific', 'us/pacific': 'US/Pacific',
         'm': 'US/Mountain', 'mst': 'US/Mountain', 'mdt': 'US/Mountain',
         'mountain': 'US/Mountain', 'us/mountain': 'US/Mountain',
         'c': 'US/Central', 'cst': 'US/Central', 'cdt': 'US/Central',
         'central': 'US/Central', 'us/central': 'US/Central',
         'e': 'US/Eastern', 'est': 'US/Eastern', 'edt': 'US/Eastern',
         'eastern': 'US/Eastern', 'us/eastern': 'US/Eastern'}
mytz = pytz.timezone(tzmap[time.tzname[0].lower()])


def recursive_print(obj, depth=0):
    if type(obj) is list:
        print '\t'*depth, '['
        for o in obj:
            recursive_print(o, depth=depth+1)
        print '\t'*depth, ']'
    elif type(obj) is tuple:
        print '\t'*depth, '('
        for o in obj:
            recursive_print(o, depth=depth+1)
        print '\t'*depth, ')'
    elif type(obj) is dict:
        print '\t'*depth, '{'
        for k, v in obj.items():
            if type(v) in (list, dict, tuple):
                print '\t'*depth, k, ':'
                recursive_print(v, depth=depth+1)
            else:
                print '\t'*depth, k, ':', v
        print '\t'*depth, '}'
    else:
        print '\t'*depth, obj


def recursive_get(obj, gets):
    """
    Will attempt to reach down each level provided in gets. Upon Key or Index exception, returns 'n/a'.
    :param obj: Nested list/dictionary structure.
    :param gets: Tuple of successive depths to reach into nested structure.
    :return: Value if valid, otherwise 'n/a' on Key or Index exception.
    """
    try:
        if len(gets) > 1:
            try:
                return recursive_get(obj.__getitem__(gets[0]), gets[1:])
            except TypeError:
                print type(obj)
                for o in obj:
                    print o
                traceback.print_exc()
        else:
            return obj.__getitem__(gets[0])
    except (KeyError, IndexError):
        return ''


def localize_to_query_timezone(time_in_query, timezone_in_query):
    if timezone_in_query.lower() in tzmap:
        query_tz = pytz.timezone(tzmap[timezone_in_query.lower()])
    elif timezone_in_query in pytz.common_timezones:
        query_tz = timezone_in_query
    else:
        print "Could not find appropriate timezone. Using local timezone."
        query_tz = mytz
    return query_tz.localize(time_in_query)


def localize_to_my_timezone(local_time):
    return mytz.localize(local_time)


def convert_to_my_timezone(local_time_from_query):
    return local_time_from_query.astimezone(mytz)


def decode_polyline(polyline_str):
    """
    Uses Google Maps polyline encoding to take polyline string back to lat/long coordinates.
    :param polyline_str: Google Maps encoded polyline
    :return: list of lat/long tuples
    """
    index, lat, lng = 0, 0, 0
    coordinates = []
    changes = {'latitude': 0, 'longitude': 0}

    # Coordinates have variable length when encoded, so just keep
    # track of whether we've hit the end of the string. In each
    # while loop iteration, a single coordinate is decoded.
    while index < len(polyline_str):
        # Gather lat/lon changes, store them in a dictionary to apply them later
        for unit in ['latitude', 'longitude']:
            shift, result = 0, 0
            while True:
                byte = ord(polyline_str[index]) - 63
                index += 1
                result |= (byte & 0x1f) << shift
                shift += 5
                if not byte >= 0x20:
                    break
            if (result & 1):
                changes[unit] = ~(result >> 1)
            else:
                changes[unit] = (result >> 1)
        lat += changes['latitude']
        lng += changes['longitude']
        coordinates.append((lat / 100000.0, lng / 100000.0))
    return coordinates


def haversine(lon1, lat1, lon2, lat2):
    """
    Calculate the great circle distance between two points on the earth (specified in decimal degrees).
    :param lon1: longitude of point 1
    :param lat1: latitude of point 1
    :param lon2: longitude of point 2
    :param lat2: latitude of point 2
    :return Distance in miles
    """
    # convert decimal degrees to radians
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
    # Haversine formula
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    # radius of earth in miles.
    r = 3956
    return c * r


def line_interpolate_points(points, fracs):
    """
    Using a series of points that make up connected line segments, interpolate the location of fractional lengths.
    :param points: list of point tuples defining connected line segments (i.e., polyline)
    :param fracs: list of fractional lengths at which to interpolate the location in cartesian space
    :return: list of point tuples with dimension the same as fracs
    """
    dist = [haversine(p1[0], p1[1], p2[0], p2[1]) for p1, p2 in zip(points[:-1], points[1:])]
    dist_sum = sum(dist)
    assert all([fr <= 1. for fr in fracs]), "Can only interpolate up to 100% of length (fracs = 1.0)."
    interp = []
    for fr in fracs:
        frd = dist_sum * fr
        dist_cumul = 0.
        for i in range(len(dist)):
            if dist_cumul + dist[i] > frd:
                p1 = points[i]
                p2 = points[i+1]
                break
            else:
                dist_cumul += dist[i]
        fp = 1. - ((frd - dist_cumul) / dist[i])
        pi = (p1[0] + (p2[0] - p1[0]) * fp, p1[1] + (p2[1] - p1[1]) * fp)
        interp.append(pi)
    return interp


def dist_to_segment(ax, ay, bx, by, cx, cy):
    """
    Computes the minimum distance between a point (cx, cy) and a line segment with endpoints (ax, ay) and (bx, by).
    :param ax: endpoint 1, x-coordinate
    :param ay: endpoint 1, y-coordinate
    :param bx: endpoint 2, x-coordinate
    :param by: endpoint 2, y-coordinate
    :param cx: point, x-coordinate
    :param cy: point, x-coordinate
    :return: minimum distance between point and line segment
    """
    # avoid divide by zero error
    a = max(by - ay, 0.00001)
    b = max(ax - bx, 0.00001)
    # compute the perpendicular distance to the theoretical infinite line
    dl = abs(a * cx + b * cy - b * ay - a * ax) / sqrt(a**2 + b**2)
    # compute the intersection point
    x = ((a / b) * ax + ay + (b / a) * cx - cy) / ((b / a) + (a / b))
    y = -1 * (a / b) * (x - ax) + ay
    # decide if the intersection point falls on the line segment
    if (ax <= x <= bx or bx <= x <= ax) and (ay <= y <= by or by <= y <= ay):
        return dl
    else:
        # if it does not, then return the minimum distance to the segment endpoints
        return min(sqrt((ax - cx)**2 + (ay - cy)**2), sqrt((bx - cx)**2 + (by - cy)**2))


def reprocess_csv(query_filename, results_pickle_filename, split_transit, cache_included=True, queries_included=True):
    from googlemaps_api_mining import GooglemapsAPIMiner
    import cPickle
    pkl = cPickle.load(open(results_pickle_filename, 'rb'))
    rp = GooglemapsAPIMiner(api_key_file=None, split_transit=split_transit)

    # need to load queries regardless of whether the full list is included in results - for the header and filename
    rp.read_input_queries(input_filename=query_filename, verbose=False)
    if queries_included:
        rp.queries = pkl['queries']

    if cache_included:
        res = sorted(pkl['results'], key=lambda x: x[0])
        cache = pkl['split_cache']
        rp.split_reverse_cache = cache
    else:
        res = sorted(pkl, key=lambda x: x[0])

    rp.results = res
    rp.output_results(write_csv=True, write_pickle=False)
    return


# Multiprocessing testing
# - had to figure out how to handle KeyboardInterrupt at parent level since execution will be long
# - also worked out a way to pass a single argument to child function (use dictionary)
def do_work(o):
    try:
        print "Started %d %s" % (os.getpid(), str(o))
        time.sleep(5)
        with open(str(o['o'])+'.txt', 'w') as f:
            f.write('Success')
        if o['o'] == 3:
            raise ValueError("Value 3")
        return 'Success'
    except KeyboardInterrupt:
        pass
    except BaseException as e:
        print "got an exception"
        print type(e)
        print e.__doc__
        print e.message
        pass


def main():
    pool = multiprocessing.Pool(4)
    p = pool.map_async(do_work, [{'a': 1, 'o': i} for i in range(8)])
    try:
        results = p.get(0xFFFFF)
    except KeyboardInterrupt:
        print 'Parent got KeyboardInterrupt'
        return

    for i in results:
        print i


if __name__ == '__main__':
    # test multiprocessing
    # main()
    inpt = './results/airports10_04_24/a100424_1.csv'
    pickle = '/Users/wbarbour1/Google Drive/Classes/CEE_418/final_project/results_local/a100424/output_a100424_1.cpkl'
    reprocess_csv(query_filename=inpt, results_pickle_filename=pickle, split_transit=True,
                  cache_included=True, queries_included=True)
