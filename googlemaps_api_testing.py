from googlemaps_query_util import *
import googlemaps
import datetime as dt
import csv
import traceback
import cPickle
import os
import time


# TODO: command line implementation

class GooglemapsAPIMiner:
    """
    Full execution class to call Google Maps Python API (googlemaps) using an input query list and outputting results
        in the form of CSV and Python pickle objects.
    """
    def __init__(self, api_key_file, queries_per_second=10):
        """
        Initialize API miner with API key to the Google Maps service. Create empty class variables for reading input
            and executing queries.
        :param api_key_file: absolute or relative path to the text file storing the Google Maps API key
        :param queries_per_second: limit sent to googlemaps module (default = 10 q/s), can also be changed with delay
            parameter in run_queries() function
        :return: None
        """
        mykey = open(api_key_file).read()
        self.gmaps = googlemaps.Client(key=mykey, queries_per_second=queries_per_second)
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
            - origin        - destination
            - mode          - waypoints
            - alternatives  - avoid
            - units         - departure_time
            - arrival_time  - optimize_waypoints
            - transit_mode  - transit_routing_parameters
            - traffic_model
        Range parameters:
            - arrival_time (arrival_time_min, arrival_time_max, arrival_time_delta)
            - departure_time (departure_time_min, departure_time_max, departure_time_delta)
            - origin [must be in lat/long] (origin_min, origin_max, origin_delta)
            - destination [must be in lat/long] (destination_min, destination_max, destination_delta]
        :param input_filename: absolute or relative path for input file (will be saved for possible use in output)
        :param verbose: T/F to print loaded queries
        :return: None
        """
        # TODO: more format checking
        with open(input_filename, 'rU') as f:
            input_reader = csv.reader(f, delimiter=',')
            self.input_header = input_reader.next()
            valid_args = inspect.getargspec(directions)[0]
            if not all([h in valid_args for h in self.input_header]):
                print set(self.input_header).difference(set(valid_args))
                raise IOError("Header contains invalid columns/arguments.")
            self.queries = [{h: v for h, v in zip(self.input_header, row) if v is not None and v != ''}
                            for row in input_reader]
        assert all(['origin' in q for q in self.queries]), "Origin point must be supplied for all queries."
        assert all(['destination' in q for q in self.queries]), "Destination point must be supplied for all queries."
        assert all(['mode' in q for q in self.queries]), "Mode must be supplied for all queries."
        self.saved_input_filename = input_filename

        # change range parameters to direct parameters
        for r in ['arrival_time', 'departure_time']:
            rs = [r + '_min', r + '_max', r + '_delta']
            for q in self.queries:
                if any([ri in q for ri in rs]):
                    assert all([ri in q for ri in rs]), "Range parameter" + r + " needs '_min', '_max', and '_delta'."
                    rmin = dt.datetime.strptime(q[r + '_min'], '%m/%d/%Y %H:%M')
                    rmax = dt.datetime.strptime(q[r + '_max'], '%m/%d/%Y %H:%M')
                    rdel = dt.timedelta(minutes=q[r + '_delta'])
                    i = 0
                    while rmin + i * rdel <= rmax:
                        qn = {}
                        for k, v in q:
                            if k not in [r] + rs:
                                qn[k] = v
                        qn[r] = rmin + i * rdel
                        self.queries.append(qn)
                        i += 1
                    self.queries.__delitem__(self.queries.index(q))
        for r in ['origin', 'destination']:
            rs = [r + '_min', r + '_max', r + '_delta']
            for q in self.queries:
                if any([ri in q for ri in rs]):
                    assert all([ri in q for ri in rs]), "Range parameter" + r + "needs '_min', '_max', and '_delta'."
                    rmin = float(q[r + '_min'])
                    rmax = float(q[r + '_max'])
                    rdel = float(q[r + '_delta'])
                    i = 0
                    while rmin + i * rdel < rmax:
                        qn = {}
                        for k, v in q:
                            if k not in [r] + rs:
                                qn[k] = v
                        qn[r] = rmin + i * rdel
                        self.queries.append(qn)
                        i += 1

        if verbose:
            for i in self.queries:
                print i
        print "Loaded", len(self.queries), "API queries."
        return

    def run_queries(self, delay=None):
        """
        Sequentially executes previously-loaded queries.
        :param delay: time (in seconds) to delay between query execution (secondary to googlemaps queries_per_second)
        :return: None
        """
        for q in self.queries:
            if 'departure_time' in q:
                if type(q['departure_time']) is str and q['departure_time'].lower() == 'now':
                    q['departure_time'] = dt.datetime.now()
                elif type(q['departure_time']) is dt.datetime:
                    pass
                else:
                    try:
                        q['departure_time'] = dt.datetime.strptime(q['departure_time'], '%m/%d/%Y %H:%M')
                    except ValueError:
                        print "Query invalid on departure_time, got", q['departure_time']
            if 'arrival_time' in q:
                if type(q['arrival_time']) is str and q['arrival_time'].lower() == 'now':
                    q['arrival_time'] = dt.datetime.now()
                elif type(q['arrival_time']) is dt.datetime:
                    pass
                else:
                    try:
                        q['arrival_time'] = dt.datetime.strptime(q['arrival_time'], '%m/%d/%Y %H:%M')
                    except ValueError:
                        print "Query invalid on departure_time, got", q['arrival_time']

            try:
                q_result = self.gmaps.directions(**q)
            except (googlemaps.exceptions.ApiError, googlemaps.exceptions.HTTPError,
                    googlemaps.exceptions.Timeout, googlemaps.exceptions.TransportError):
                traceback.print_exc()
                continue

            # recursive_print(q_result)
            self.results.append(q_result)

            # delay sequential execution, if indicated
            if delay:
                time.sleep(delay)
        return

    def output_results(self, output_filename=None, write_csv=True, write_pickle=True):
        """
        Write previously-gathered query results to file(s).
        :param output_filename: (optional) override 'output_' + input_filename for output files
        :param write_csv: write output as CSV file (distance, duration, start(x, y), end(x, y))
        :param write_pickle: write results to pickle file, full query returns in list
        :return: None
        """
        if not self.results:
            return
        if output_filename is None:
            output_filename = 'output_' + os.path.splitext(os.path.split(self.saved_input_filename)[-1])[0]
        if write_pickle:
            with open(output_filename + '.cpkl', 'wb') as f:
                cPickle.dump(self.results, f)
        if write_csv:
            # define output parameters and the appropriate depth-wise calls to list-dict combinations to get each
            outputs = {'distance': (0, 'legs', 0, 'distance', 'text'),
                       'duration': (0, 'legs', 0, 'duration', 'text'),
                       'start_x': (0, 'legs', 0, 'start_location', 'lng'),
                       'start_y': (0, 'legs', 0, 'start_location', 'lat'),
                       'end_x': (0, 'legs', 0, 'end_location', 'lng'),
                       'end_y': (0, 'legs', 0, 'end_location', 'lat')}
            with open(output_filename + '.csv', 'w') as f:
                writer = csv.writer(f, delimiter='|')
                outputs_keys, outputs_values = zip(*outputs.items())
                output_header = self.input_header + list(outputs_keys)
                writer.writerow(output_header)
                for q, r in zip(self.queries, self.results):
                    line = [q[ih] if ih in q else ''
                            for ih in self.input_header] + [recursive_get(r, oh)
                                                            for oh in outputs_values]
                    writer.writerow(line)
        return

    def run_pipeline(self, input_filename, output_filename=None, verbose=False, write_csv=True, write_pickle=True):
        """
        Executes read_input_queries(...), run_queries(...), and output_results(...) with their relevant parameters
        :param input_filename: absolute or relative path for input file (will be saved for possible use in output)
        :param output_filename: (optional) override 'output_' + input_filename for output files
        :param verbose: T/F to print loaded queries
        :param write_csv: write output as CSV file (distance, duration, start(x, y), end(x, y))
        :param write_pickle: write results to pickle file, full query returns in list
        :return: None
        """
        self.read_input_queries(input_filename=input_filename, verbose=verbose)
        self.run_queries()
        self.output_results(output_filename=output_filename, write_csv=write_csv, write_pickle=write_pickle)
        return


if __name__ == '__main__':
    key_file = '/Users/wbarbour1/Google Drive/Classes/CEE_418/final_project/googlemaps_api_key.txt'
    input_file = './test_queries.csv'
    g = GooglemapsAPIMiner(api_key_file=key_file)
    g.run_pipeline(input_filename=input_file, verbose=True)
