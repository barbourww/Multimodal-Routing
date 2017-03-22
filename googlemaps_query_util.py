import pytz
import traceback
import time
import multiprocessing
import os

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
        return 'n/a'


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
    main()
