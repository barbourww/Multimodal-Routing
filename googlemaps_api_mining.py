from googlemaps_query_util import *
import googlemaps
import datetime as dt
import csv
import traceback
import cPickle
import os
from itertools import product, chain
import sys
import getopt
from inspect import getargspec


class GooglemapsAPIMiner:
    """
    Full execution class to call Google Maps Python API (googlemaps) using an input query list and outputting results
        in the form of CSV and Python pickle objects.
    """
    def __init__(self, api_key_file, execute_in_time=False, queries_per_second=10):
        """
        Initialize API miner with API key to the Google Maps service. Create empty class variables for reading input
            and executing queries.
        :param api_key_file: absolute or relative path to the text file storing the Google Maps API key
        :param execute_in_time: wait until the departure time indicated to execute the query as departure_time='now'
        :param queries_per_second: limit sent to googlemaps module (default = 10 q/s), can also be changed with delay
            parameter in run_queries() function
        :return: None
        """
        mykey = open(api_key_file, 'r').read()
        self.gmaps = googlemaps.Client(key=mykey, queries_per_second=queries_per_second)
        self.execute_in_time = execute_in_time
        self.results = []
        self.queries = None
        self.input_header = None
        self.saved_input_filename = None
        return

    def read_input_queries(self, input_filename, verbose=False):
        """
        Reads CSV file with header to get list of queries. Some columns are direct and some are range parameters.
        See README.txt for more information on each and tips on formatting input documents.
        Direct parameters:
            - origin (required)
            - destination (required)
            - mode (required)
            - waypoints     - traffic_model
            - alternatives  - avoid
            - units         - departure_time
            - arrival_time  - optimize_waypoints
            - transit_mode  - transit_routing_parameters
        Range parameters:
            - arrival_time (arrival_time_min, arrival_time_max, arrival_time_delta)
            - departure_time (departure_time_min, departure_time_max, departure_time_delta)
            - origin [must be in lat/long] (origin_min, origin_max, origin_delta)
            - destination [must be in lat/long] (destination_min, destination_max, destination_delta]
        :param input_filename: absolute or relative path for input file (will be saved for possible use in output)
        :param verbose: T/F to print loaded queries
        :return: None
        """
        # Valid range parameters
        date_rp = (['arrival_time', 'departure_time'], ['_min', '_max', '_delta'])
        loc_rp = (['origin', 'destination'], ['_min', '_max', '_count', '_arrange'])

        with open(input_filename, 'rU') as f:
            input_reader = csv.reader(f, delimiter=',', quotechar='"')
            self.input_header = input_reader.next()
            valid_args = getargspec(googlemaps.directions.directions)[0] + ['timezone'] \
                         + [va[0] + va[1] for va in product(date_rp[0], date_rp[1])] \
                         + [va[0] + va[1] for va in product(loc_rp[0], loc_rp[1])]
            if not all([h in valid_args for h in self.input_header]):
                print "Invalid:", set(self.input_header).difference(set(valid_args))
                raise IOError("Header contains invalid columns/arguments.")
            self.queries = [{h: v for h, v in zip(self.input_header, row) if v is not None and v != ''}
                            for row in input_reader if not row[0].startswith('#')]
        assert all(['origin' in q or 'origin_min' in q for q in self.queries]), \
            "Origin point must be supplied for all queries."
        assert all(['destination' in q or 'destination_min' in q for q in self.queries]), \
            "Destination point must be supplied for all queries."
        assert all(['mode' in q for q in self.queries]), "Mode must be supplied for all queries."
        assert all(['timezone' in q for q in self.queries]), "Timezone must be supplied for all queries."

        # Keep input filename in case output filename goes to default (input filename + '_output').
        self.saved_input_filename = input_filename

        # Parse out '|'-delimited waypoints, if supplied.
        for q in self.queries:
            if 'waypoints' in q:
                q['waypoints'] = q['waypoints'].split('|')

        # Track the list indices of queries with range parameters for removal later.
        remove_indices = []
        # Change range parameters to direct parameters.
        for r in date_rp[0]:
            rs = [r + suf for suf in date_rp[1]]
            for q in self.queries:
                if any([ri in q for ri in rs]):
                    if not all([ri in q for ri in rs]):
                        print "Range param", r, "needs", date_rp[1]
                        print q
                        remove_indices.append(self.queries.index(q))
                        continue

                    try:
                        rmin = dt.datetime.strptime(q[r + '_min'], '%m/%d/%Y %H:%M')
                    except ValueError:
                        print "Problem with query format on", r+'_min', "(couldn't convert to datetime)."
                        print q
                        remove_indices.append(self.queries.index(q))
                        continue
                    assert rmin > dt.datetime.now(), "Departure/Arrival times must be in future."

                    try:
                        rmax = dt.datetime.strptime(q[r + '_max'], '%m/%d/%Y %H:%M')
                    except ValueError:
                        print "Problem with query format on", r+'_max', "(couldn't convert to datetime)."
                        print q
                        remove_indices.append(self.queries.index(q))
                        continue
                    assert rmax > rmin, "Max time is not greater than min time."

                    rdel = dt.timedelta(minutes=int(q[r + '_delta']))
                    i = 0
                    while rmin + i * rdel <= rmax:
                        qn = {}
                        for k, v in q.items():
                            if k not in [r] + rs:
                                qn[k] = v
                        qn[r] = rmin + i * rdel
                        self.queries.append(qn)
                        i += 1
                    remove_indices.append(self.queries.index(q))
                elif r in q:
                    if type(q[r]) is str and q[r].lower() != 'now':
                        try:
                            q[r] = dt.datetime.strptime(q[r], '%m/%d/%Y %H:%M')
                        except ValueError:
                            print "Problem with query format on", r, "('now' not used and couldn't convert to datetime)"
                            print q
                            remove_indices.append(self.queries.index(q))
        # Remove queries that contained range parameters.
        if remove_indices:
            self.queries = [self.queries[j] for j in range(len(self.queries)) if j not in remove_indices]
        remove_indices = []

        for q in self.queries:
            qtz = q['timezone']
            for r in date_rp[0] + [ri[0] + ri[1] for ri in product(date_rp[0], date_rp[1])]:
                if r in q and q[r].lower() != 'now':
                    q[r] = convert_to_my_timezone(localize_to_query_tz(time_in_query=q[r], timezone_in_query=qtz))
            q.__delitem__('timezone')

        for r in loc_rp[0]:
            rs = [r + suf for suf in loc_rp[1]]
            for q in self.queries:
                if any([ri in q for ri in rs]):
                    if not all([ri in q for ri in rs]):
                        print "Range param", r, "needs", loc_rp[1]
                        print q
                        remove_indices.append(self.queries.index(q))
                        continue
                    rmin = (float(q[r + '_min'].split(';')[0]), float(q[r + '_min'].split(';')[1]))
                    rmax = (float(q[r + '_max'].split(';')[0]), float(q[r + '_max'].split(';')[1]))
                    rdiv = (int(q[r + '_count'].split(';')[0]), int(q[r + '_count'].split(';')[1]))
                    rarr = q[r + '_arrange']
                    rdel = ((rmax[0] - rmin[0]) / (rdiv[0] - 1), (rmax[1] - rmin[1]) / (rdiv[1] - 1))
                    rvals = ([rmin[0] + i * rdel[0] for i in range(rdiv[0])],
                             [rmin[1] + i * rdel[1] for i in range(rdiv[1])])
                    if rarr == 'line':
                        rq = zip(rvals[0], rvals[1])
                    elif rarr == 'grid':
                        rq = [i for i in product(rvals[0], rvals[1])]
                    else:
                        print "Invalid arrangement argument. Use 'line' or 'grid'."
                        print q
                        remove_indices.append(self.queries.index(q))
                        continue
                    for rv in rq:
                        qn = {}
                        for k, v in q.items():
                            if k not in [r] + rs:
                                qn[k] = v
                        qn[r] = rv
                        self.queries.append(qn)
                    remove_indices.append(self.queries.index(q))
                else:
                    if ';' in q[r]:
                        try:
                            q[r] = tuple([float(i) for i in q[r].split(';')])
                        except ValueError:
                            print "Problem with query format on", r, "(';' included but couldn't convert to lat/long)"
                            print q
                            remove_indices.append(self.queries.index(q))
        # Remove queries that contained range parameters.
        if remove_indices:
            self.queries = [self.queries[j] for j in range(len(self.queries)) if j not in remove_indices]

        if verbose:
            for i in self.queries:
                print i

        # Redefine input header to remove columns that are unused or no longer needed (e.g., range parameters)
        # This will be used later in output files.
        self.input_header = list(set(chain(*[tuple(q.keys()) for q in self.queries])))
        # Sort queries for execution in order.
        if self.execute_in_time:
            self.queries.sort(key=lambda x: x['departure_time'])
        print "Loaded", len(self.queries), "API queries."
        return

    def run_queries(self, verbose=False):
        """
        Sequentially executes previously-loaded queries.
        :param verbose: runs recursive print (for legible indention) on each query result
        :return: None
        """
        for q in self.queries:
            if 'departure_time' in q:
                # q['departure_time'] should have already been converted to dt.datetime unless it is 'now'
                if type(q['departure_time']) is str and q['departure_time'].lower() == 'now':
                    q['departure_time'] = dt.datetime.now()
                elif type(q['departure_time']) is dt.datetime:
                    pass
                else:
                    raise ValueError("Invalid type for parameter 'departure_time'.")
            if 'arrival_time' in q:
                # q['arrival_time'] should have already been converted to dt.datetime unless it is 'now'
                if type(q['arrival_time']) is str and q['arrival_time'].lower() == 'now':
                    q['arrival_time'] = dt.datetime.now()
                elif type(q['arrival_time']) is dt.datetime:
                    pass
                else:
                    raise ValueError("Invalid type for parameter 'arrival_time'.")

            if self.execute_in_time:
                # All queries were checked that they were in the future during ingestion, but if queries multiple
                #   were given the same departure_time, then time.sleep() would be for negative number of seconds.
                # Therefore, just skip sleeping.
                if q['departure_time'] > dt.datetime.now():
                    print "Waiting for next query at", q['departure_time'].strftime("%m/%d/%Y %H:%M")
                    time.sleep((q['departure_time'] - dt.datetime.now()).total_seconds())
                # Put in the exact current time for precision as indicated by googlemaps package documentation.
                q['departure_time'] = dt.datetime.now()

            try:
                q_result = self.gmaps.directions(**q)
            except (googlemaps.exceptions.ApiError, googlemaps.exceptions.HTTPError,
                    googlemaps.exceptions.Timeout, googlemaps.exceptions.TransportError):
                traceback.print_exc()
                continue
            if verbose:
                recursive_print(q_result)
                print '\n\n'
            self.results.append(q_result)
        print "Executed", len(self.results), "queries successfully."
        return

    def output_results(self, output_filename=None, write_csv=True, write_pickle=True, get_outputs=None):
        """
        Write previously-gathered query results to file(s).
        :param output_filename: (optional) override 'output_' + input_filename for output files (no extension needed)
        :param write_csv: write output as CSV file (distance, duration, start(x, y), end(x, y))
        :param write_pickle: write results to pickle file, full query returns in list
        :param get_outputs: dict of column headers (keys) with tuples of the depth-wise calls to make to the list-dict
            results gathered; already defined within function, but these may not be valid depending on queries
        :return: None
        """
        if not self.results:
            return
        if output_filename is None:
            output_stub = os.path.split(self.saved_input_filename)[0]
            output_fn = 'output_' + os.path.splitext(os.path.split(self.saved_input_filename)[-1])[0]
        else:
            output_stub = os.path.split(output_filename)[0]
            output_fn = os.path.splitext(os.path.split(output_filename)[-1])[0]
        if write_pickle:
            try:
                with open(output_stub + '/' + output_fn + '.cpkl', 'wb') as f:
                    cPickle.dump(self.results, f)
            except:
                traceback.print_exc()
                print "Problem with output as pickle."
                print "Attempting to save as file './exception_dump.cpkl'."
                print "Rename that file to recover results, it may be overwritten if output fails again."
                with open("./exception_dump.cpkl", 'wb') as f:
                    cPickle.dump(self.results, f)
        if write_csv:
            try:
                # define output parameters and the appropriate depth-wise calls to list-dict combinations to get each
                if get_outputs:
                    outputs = get_outputs
                else:
                    outputs = {'distance': (0, 'legs', 0, 'distance', 'text'),
                               'duration': (0, 'legs', 0, 'duration_in_traffic', 'text'),
                               'start_x': (0, 'legs', 0, 'start_location', 'lng'),
                               'start_y': (0, 'legs', 0, 'start_location', 'lat'),
                               'end_x': (0, 'legs', 0, 'end_location', 'lng'),
                               'end_y': (0, 'legs', 0, 'end_location', 'lat')}
                with open(output_stub + '/' + output_fn + '.csv', 'w') as f:
                    writer = csv.writer(f, delimiter='|')
                    outputs_keys, outputs_values = zip(*outputs.items())
                    output_header = self.input_header + list(outputs_keys)
                    writer.writerow(output_header)
                    for q, r in zip(self.queries, self.results):
                        line = [q[ih] if ih in q else ''
                                for ih in self.input_header] + [recursive_get(r, oh)
                                                                for oh in outputs_values]
                        writer.writerow(line)
            except:
                traceback.print_exc()
                print "Problem with output as CSV."
                if not write_pickle:
                    print "Attempting to save results as pickle at './exception_dump.cpkl'."
                    print "Rename that file to recover results, it may be overwritten if output fails again."
                    with open("./exception_dump.cpkl", 'wb') as f:
                        cPickle.dump(self.results, f)
        return

    def run_pipeline(self, input_filename, output_filename=None, verbose_input=False, verbose_execute=False,
                     write_csv=True, write_pickle=True):
        """
        Executes read_input_queries(...), run_queries(...), and output_results(...) with their relevant parameters
        :param input_filename: absolute or relative path for input file (will be saved for possible use in output)
        :param output_filename: (optional) override 'output_' + input_filename for output files
        :param verbose_input: T/F to print loaded queries
        :param verbose_execute: T/F to print executed query results
        :param write_csv: write output as CSV file (distance, duration, start(x, y), end(x, y))
        :param write_pickle: write results to pickle file, full query returns in list
        :return: None
        """
        self.read_input_queries(input_filename=input_filename, verbose=verbose_input)
        self.run_queries(verbose=verbose_execute)
        self.output_results(output_filename=output_filename, write_csv=write_csv, write_pickle=write_pickle)
        return


if __name__ == '__main__':
    if True:
        key_file = './will_googlemaps_api_key.txt'
        input_file = './test_queries.csv'
        g = GooglemapsAPIMiner(api_key_file=key_file)
        #g.read_input_queries(input_filename=input_file, verbose=True)
        #raise KeyboardInterrupt
        g.run_pipeline(input_filename=input_file, verbose_input=True, verbose_execute=True)
        sys.exit(0)
    usage = """
    usage: googlemaps_api_mining.py -k <api_key_file> -i <input_file>
            --[execute_in_time, queries_per_second, output_filename, write_csv, write_pickle]
    ex: python googlemaps_api_mining.py -k "./api_key.txt" -i "./test_queries.csv" --output_file "./output_test.csv"
    """
    arg = sys.argv[1:]

    initargs = getargspec(GooglemapsAPIMiner.__init__)
    req = zip(initargs.args[1:-len(initargs.defaults)], [None]*len(initargs.args[1:-len(initargs.defaults)]))
    initspec = {k: v for k, v in req + zip(initargs.args[-len(initargs.defaults):], initargs.defaults)}
    rpargs = getargspec(GooglemapsAPIMiner.run_pipeline)
    req = zip(rpargs.args[1:-len(rpargs.defaults)], [None]*len(rpargs.args[1:-len(rpargs.defaults)]))
    rpspec = {k: v for k, v in req + zip(rpargs.args[-len(rpargs.defaults):], rpargs.defaults)}

    try:
        opts, args = getopt.getopt(arg, "hk:i:", ["queries_per_second=", "output_filename=",
                                                  "write_csv=", "write_pickle="])
    except getopt.GetoptError:
        print usage
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print usage
            sys.exit()

        elif opt in ("-k", "--api_key_file"):
            initspec['api_key_file'] = arg
        elif opt == "--queries_per_second":
            initspec['queries_per_second'] = int(arg)
        elif opt == "--execute_in_time":
            if arg.lower() == 'true':
                initspec['execute_in_time'] = True
            elif arg.lower() == 'false':
                initspec['execute_in_time'] = False
            else:
                print "--execute_in_time should be [True/False/TRUE/FALSE/true/false]"

        elif opt in ("-i", "--input_filename"):
            rpspec['input_filename'] = arg
        elif opt == "--output_filename":
            rpspec['output_filename'] = arg
        elif opt == "--write_csv":
            if arg.lower() == 'true':
                rpspec['write_csv'] = True
            elif arg.lower() == 'false':
                rpspec['write_csv'] = False
            else:
                print "--write_csv should be [True/False/TRUE/FALSE/true/false]"
                sys.exit(2)
        elif opt == "--write_pickle":
            if arg.lower() == 'true':
                rpspec['write_pickle'] = True
            elif arg.lower() == 'false':
                rpspec['write_pickle'] = False
            else:
                print "--write_pickle should be [True/False/TRUE/FALSE/true/false]"
                sys.exit(2)

    g = GooglemapsAPIMiner(**initspec)
    g.run_pipeline(**rpspec)
