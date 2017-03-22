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
import multiprocessing
from copy import copy


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

        # Keep input filename in case output filename goes to default ('output_' + input filename).
        if os.path.split(input_filename)[0] == '':
            self.saved_input_filename = './' + input_filename
        else:
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
                if r in q and type(q[r]) is dt.datetime:
                    q[r] = convert_to_my_timezone(localize_to_query_timezone(time_in_query=q[r], timezone_in_query=qtz))
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
            for tt in ('departure_time', 'arrival_time'):
                if tt in q:
                    # q[tt] should have already been converted to dt.datetime unless it is 'now'
                    if type(q[tt]) is str and q[tt].lower() == 'now':
                        q[tt] = dt.datetime.now()
                    elif type(q[tt]) is dt.datetime:
                        pass
                    else:
                        raise ValueError("Invalid type for parameter '%s'." % tt)

            if self.execute_in_time:
                # All queries were checked that they were in the future during ingestion, but if queries multiple
                #   were given the same departure_time, then time.sleep() would be for negative number of seconds.
                # Therefore, just skip sleeping and execute at 'now'.
                print "Query departure_time:", q['departure_time']
                print "Now:", localize_to_my_timezone(dt.datetime.now())
                t = q['departure_time'] - localize_to_my_timezone(dt.datetime.now())
                if t > dt.timedelta(0):
                    print "Waiting for next query at", q['departure_time'].strftime("%m/%d/%Y %H:%M")
                    print "Sleep for", str(t).split('.')[0]
                    time.sleep(t.total_seconds())
                # Put in the exact current time for precision as indicated by googlemaps package documentation.
                q['departure_time'] = dt.datetime.now()
                print "Executing now (%s)." % q['departure_time'].strftime("%m/%d/%Y %H:%M")

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
            if os.path.split(output_filename)[0] == '':
                output_stub = './'
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
                    for q, res in zip(self.queries, self.results):
                        line = [q[ih] if ih in q else ''
                                for ih in self.input_header] + [recursive_get(res, oh)
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


def parallel_run_pipeline(all_args):
    """

    :param all_args:
    :return:
    """
    try:
        pipeline_args = all_args['pipeline_args']
        print "Process", os.getpid(), "pipeline_args:", pipeline_args
        init_args = all_args['init_args']
        print "Process", os.getpid(), "init_args:", init_args
        print "Beginning execution of input %s with PID %d." % (pipeline_args['input_filename'], os.getpid())
        GooglemapsAPIMiner(**init_args).run_pipeline(**pipeline_args)
        print "Execution of input %s with PID %d was successful." % (pipeline_args['input_filename'], os.getpid())
        return "Success"
    except KeyboardInterrupt:
        pass
    except BaseException as e:
        print "Exception raised on PID %d..." % os.getpid()
        print type(e), e.message
        return "Failure"


if __name__ == '__main__':
    # Set to True for running easily within IDE.
    if False:
        key_file = './will_googlemaps_api_key.txt'
        input_file = './test_queries.csv'
        g = GooglemapsAPIMiner(api_key_file=key_file, execute_in_time=True)
        # g.read_input_queries(input_filename=input_file, verbose=True)
        # raise KeyboardInterrupt
        g.run_pipeline(input_filename=input_file, verbose_input=True, verbose_execute=False)
        sys.exit(0)

    usage = """
    usage: googlemaps_api_mining.py -k <api_key_file> -i <input_filename>
            --[execute_in_time, queries_per_second, output_filename, write_csv, write_pickle,
                parallel_input_files, parallel_api_key_files]
    ex: python googlemaps_api_mining.py -k "./api_key.txt" -i "./test_queries.csv" --output_file "./output_test.csv"
    note: it is advised that the query input filenames be given as an absolute path
    note: using --parallel_input_files overrides output_filename and other parameters will be used for all tasks
    note: to check number of allowable parallel processes use... googlemaps_api_mining.py -c
    """
    # Collect command line arguments/options.
    command_line_arguments = sys.argv[1:]

    # Make default argument list for class initialization and pipeline execution.
    initargs = getargspec(GooglemapsAPIMiner.__init__)
    req = zip(initargs.args[1:-len(initargs.defaults)], [None]*len(initargs.args[1:-len(initargs.defaults)]))
    initspec = {k: v for k, v in req + zip(initargs.args[-len(initargs.defaults):], initargs.defaults)}
    rpargs = getargspec(GooglemapsAPIMiner.run_pipeline)
    req = zip(rpargs.args[1:-len(rpargs.defaults)], [None]*len(rpargs.args[1:-len(rpargs.defaults)]))
    rpspec = {k: v for k, v in req + zip(rpargs.args[-len(rpargs.defaults):], rpargs.defaults)}
    # Make space for additional input file names and API key file names for parallel execution.
    add_inputs = []
    add_keys = []

    try:
        opts, args = getopt.getopt(command_line_arguments, "hck:i:",
                                   ["execute_in_time=", "queries_per_second=", "output_filename=", "write_csv=",
                                    "write_pickle=", "parallel_input_files=", "parallel_api_key_files="])
    except getopt.GetoptError:
        print usage
        sys.exit(2)

    for opt, arg in opts:
        # Information options.
        if opt == "-h":
            print usage
            sys.exit(0)
        elif opt == "-c":
            print "This system can safely execute %i mining processes in parallel." % multiprocessing.cpu_count()
            print "Provide one input file using -i and %i more with --parallel_input_files option, '|'-delimited." % \
                  (multiprocessing.cpu_count() - 1)
            sys.exit(0)

        # Initialization arguments.
        elif opt == "-k":
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
                sys.exit(2)

        # Pipeline arguments.
        elif opt == "-i":
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

        # Parallel execution arguments.
        elif opt == "--parallel_input_files":
            add_inputs = arg.split('|')
            # With the addition of the other input supplied by -i, the input file count must not exceed CPU cores.
            assert (len(add_inputs) + 1) <= multiprocessing.cpu_count(), \
                "Exceeded number of allowable processes. Use -c for info on processor availability."
        elif opt == "--parallel_api_key_files":
            add_keys = arg.split('|')

    if add_inputs:
        # Assemble full list of inputs. Then 'input_filename' in rpspec can be overwritten.
        add_inputs.append(copy(rpspec['input_filename']))
        # Assemble full list of API keys. Then 'api_key_file' in initspec can be overwritten.
        # Primary API key provided in argument '-k', which will be the API key to be used more than once.
        if add_keys:
            add_keys.append(copy(initspec['api_key_file']))
            print "Loaded additional API keys for a total of", len(add_keys), "keys."
            if len(add_keys) < len(add_inputs):
                print "Fewer keys than input files. Primary will be used", len(add_inputs) - len(add_keys) + 1, "times."
        print "Full filename list:"
        for fn in add_inputs:
            print '\t', fn
        # Need copies of pipeline argument spec with appropriate input file names.
        pipes = []
        inits = []
        for ai_i in range(len(add_inputs)):
            rpspec['input_filename'] = add_inputs[ai_i]
            # The minimum function will use API keys in order they were provided in 'parallel_api_key_files' followed
            #   by the primary API key in option '-k', the latter of which will be used multiple times if necessary.
            initspec['api_key_file'] = add_keys[min(ai_i, len(add_keys))]
            # Duplicate initspec filled with one of the input file names and API key file names.
            pipes.append(copy(rpspec))
            inits.append(copy(initspec))
        print "Built list of", len(pipes), "argument specs for pipeline execution."

        pool = multiprocessing.Pool(multiprocessing.cpu_count())
        print "Assembled pool of", multiprocessing.cpu_count(), "processes."
        p = pool.map_async(parallel_run_pipeline, [{'init_args': i, 'pipeline_args': p} for i, p in zip(inits, pipes)])
        try:
            # Timeout set at approximately 12 days.
            results = p.get(0xFFFFF)
        except KeyboardInterrupt:
            print 'Multiprocessing got KeyboardInterrupt. Terminating...'
            sys.exit(1)

        print "Parallel execution results:"
        for r in results:
            print r
    else:
        g = GooglemapsAPIMiner(**initspec)
        g.run_pipeline(**rpspec)
