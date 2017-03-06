import pytz
import traceback
import time

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


def localize_to_query_tz(time_in_query, timezone_in_query):
    query_tz = pytz.timezone(tzmap[timezone_in_query.lower()])
    return query_tz.localize(time_in_query)


def convert_to_my_timezone(local_time_from_query):
    return local_time_from_query.astimezone(mytz)
