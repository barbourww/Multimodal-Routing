import datetime as dt
from numpy.random import RandomState


class TVEdge:
    """

    """
    def __init__(self, data_map, tv_type):
        assert tv_type in ['day:hour', 'day:schedule', None], "Invalid time-variant type."
        self.tv_type = tv_type

        assert type(data_map) in [dict, float], "Data must be a dictionary or float type."

        # day_map = {'monday': 1, 'tuesday': 2, 'wednesday': 3, 'thursday': 4, 'friday': 5, 'saturday': 6, 'sunday': 7}
        # assert all([k.lower() in day_map.keys() for k in data_map.keys()]), "Data input keys are not day names."
        assert all([type(k) is dt.date for k in data_map.keys()]), "Data input keys are not date objects."
        if self.tv_type == 'day:hour':
            assert all([type(v) is dict for v in data_map.values()]), "day:hour type takes data as dict of dicts."
        elif self.tv_type == 'day:schedule':
            assert all([type(v) is list for v in data_map.values()]), "day:schedule type takes data as dict of lists."
        elif self.tv_type is None:
            assert type(data_map) is float, "If edge is not time-variant, data should be provided as a float."
        # change dictionary keys to weekday numbers for compatibility with isoweekday() output
        # verified that this will not interfere with objects shared between keys
        # self.data = {day_map[k.lower()]: v for k, v in data_map.items()}
        self.data = data_map

    def get_weight(self, date_time, how, error_magnitude=0., error_type=None):
        if self.tv_type == 'day:hour':
            if how == 'linear':
                day = date_time.date()
                m = (self.data[day][date_time.hour + 1] - self.data[day][date_time.hour])
                w = self.data[day][date_time.hour] + m * (date_time.minutes / 60)
            elif how == 'last':
                w = self.data[date_time.day()][date_time.hour]
            elif how == 'next':
                w = self.data[date_time.day()][date_time.hour + 1]
            else:
                raise AttributeError("Invalid input for argument 'how'.")
        elif self.tv_type == 'day:schedule':
            w = min([t - date_time.time() for t in self.data[date_time.isoweekday()] if t > date_time.time()])
        elif self.tv_type is None:
            w = self.data
        else:
            raise TypeError("Time variance type corrupted.")

        if error_type.lower() in ['normal', 'gaussian']:
            w += RandomState.normal(loc=error_magnitude[0], scale=error_magnitude[1])
        elif error_type.lower() == 'uniform':
            w += RandomState.uniform(low=error_magnitude[0], high=error_magnitude[1])
        else:
            pass

        return w
