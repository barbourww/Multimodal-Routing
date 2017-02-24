import csv
from googlemaps.directions import directions
import inspect
import traceback


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
