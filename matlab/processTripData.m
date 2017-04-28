function processTripData(inputFile, targetName)
%% FUNCTION PROCESSTRIPDATA
% Data processing from imported data to output to Excel. Assuming all unit
% conversions were already performed in earlier import step.
% Output in two formats - mat and xlsx.

%% Load input mat file
tempload = load(inputFile);
Tin = tempload.T; clear tempload;

%% Initialize Final Name/Unit Vectors
varnames = {
    'Origin_name'               % 1
    'Origin_lat'                % 2
    'Origin_lon'                % 3
    'Destination_name'          % 4
    'Destination_lat'           % 5
    'Destination_lon'           % 6
    'SplitPt_name'              % 7
    'SplitPt_lat'               % 8
    'SplitPt_lon'               % 9
    'Date'                      % 10
    'Day'                       % 11
    'Local_time'                % 12
    'Drive_leg1_distance'       % 13
    'Drive_leg1_duration'       % 14
    'Transit_leg1_distance'     % 15
    'Transit_leg1_duration'     % 16
    'Drive_leg2_distance'       % 17
    'Drive_leg2_duration'       % 18
    'Transit_leg2_distance'     % 19
    'Transit_leg2_duration'     % 20
    'Duration_bin'              % 21
    'Distance_bin'              % 22
    };
varunits = {
    ''                          % 1
    'degrees'                   % 2
    'degrees'                   % 3
    ''                          % 4
    'degrees'                   % 5
    'degrees'                   % 6
    ''                          % 7
    'degrees'                   % 8
    'degrees'                   % 9
    ''                          % 10
    ''                          % 11
    ''                          % 12
    'miles'                     % 13
    'minutes'                   % 14
    'miles'                     % 15
    'minutes'                   % 16
    'miles'                     % 17
    'minutes'                   % 18
    'miles'                     % 19
    'minutes'                   % 20
    ''                          % 21
    ''                          % 22
    };

%% Preprocessing on all rows
% Split departure_time to date, day, and time
Tin.date = dateshift(Tin.departure_time, 'start', 'day');
Tin.day = day(Tin.departure_time, 'dayofweek'); % sun = 1, sat = 7
timestrings = datestr(Tin.departure_time);
Tin.time = timestrings(:, end-7:end);

% Tin now has 27 columns

%% 1. Process drive only
% Criteria: 
% Col 2 split_on_leg = ''
% Col 6 mode = 'driving'
% Col 10 split_point = ''
% Col 21 distance_leg2 = NaN

Tdrive = Tin(strcmp(Tin.split_on_leg,'') & strcmp(Tin.mode,'driving') & ...
    strcmp(Tin.split_point,'') & isnan(Tin.distance_leg2), :);

% Take max of durations
Tdrive.duration = max(Tdrive.duration_in_traffic_leg1, ...
    Tdrive.duration_leg1); % 28 cols now

% Initialize empty table
nrowsd = size(Tdrive,1);
Tdrive_new = cell2table(cell(nrowsd,22), 'VariableNames', varnames);
Tdrive_new.Properties.VariableUnits = varunits;

% Assign old table columns to new
Tdrive_new.Origin_name = Tdrive.origin;
Tdrive_new.Origin_lat = Tdrive.start_y_leg1;
Tdrive_new.Origin_lon = Tdrive.start_x_leg1;
Tdrive_new.Destination_name = Tdrive.destination;
Tdrive_new.Destination_lat = Tdrive.end_y_leg1;
Tdrive_new.Destination_lon = Tdrive.end_x_leg1;
Tdrive_new.Date = Tdrive.date;
Tdrive_new.Day = Tdrive.day;
Tdrive_new.Local_time = Tdrive.time;
Tdrive_new.Drive_leg1_distance = Tdrive.distance_leg1;
Tdrive_new.Drive_leg1_duration = Tdrive.duration;

% Set data type for empty numerical columns
nancold = NaN(nrowsd, 1);
Tdrive_new.SplitPt_lat = nancold;
Tdrive_new.SplitPt_lon = nancold;
Tdrive_new.Transit_leg1_distance = nancold;
Tdrive_new.Transit_leg1_duration = nancold;
Tdrive_new.Drive_leg2_distance = nancold;
Tdrive_new.Drive_leg2_duration = nancold;
Tdrive_new.Transit_leg2_distance = nancold;
Tdrive_new.Transit_leg2_duration = nancold;
Tdrive_new.Duration_bin = nancold;
Tdrive_new.Distance_bin = nancold;


%% 2. Process transit only
% Criteria: 
% Col 6 mode = 'transit'
% Col 10 split_point = ''
% Col 21 distance_leg2 = NaN

Ttransit = Tin(strcmp(Tin.mode,'transit') & ...
    strcmp(Tin.split_point,'') & isnan(Tin.distance_leg2), :);

% Initialize empty table
nrowst = size(Ttransit,1);
Ttransit_new = cell2table(cell(nrowst,22), 'VariableNames', varnames);
Ttransit_new.Properties.VariableUnits = varunits;

% Assign old table columns to new
Ttransit_new.Origin_name = Ttransit.origin;
Ttransit_new.Origin_lat = Ttransit.start_y_leg1;
Ttransit_new.Origin_lon = Ttransit.start_x_leg1;
Ttransit_new.Destination_name = Ttransit.destination;
Ttransit_new.Destination_lat = Ttransit.end_y_leg1;
Ttransit_new.Destination_lon = Ttransit.end_x_leg1;
Ttransit_new.Date = Ttransit.date;
Ttransit_new.Day = Ttransit.day;
Ttransit_new.Local_time = Ttransit.time;
Ttransit_new.Transit_leg1_distance = Ttransit.distance_leg1;
Ttransit_new.Transit_leg1_duration = Ttransit.duration_leg1;

% Set data type for empty numerical columns
nancolt = NaN(nrowst, 1);
Ttransit_new.SplitPt_lat = nancolt;
Ttransit_new.SplitPt_lon = nancolt;
Ttransit_new.Drive_leg1_distance = nancolt;
Ttransit_new.Drive_leg1_duration = nancolt;
Ttransit_new.Drive_leg2_distance = nancolt;
Ttransit_new.Drive_leg2_duration = nancolt;
Ttransit_new.Transit_leg2_distance = nancolt;
Ttransit_new.Transit_leg2_duration = nancolt;
Ttransit_new.Duration_bin = nancolt;
Ttransit_new.Distance_bin = nancolt;

%% 3. Process drive -> transit
% Criteria: 
% Col 3 drive_leg = 'start'
% Col 10 split_point ~= ''
% Col 21 distance_leg2 ~= NaN

Tdt = Tin(strcmp(Tin.drive_leg,'start') & ...
    ~strcmp(Tin.split_point,'') & ~isnan(Tin.distance_leg2), :);

% Take max of durations for leg 1 driving
Tdt.duration1 = max(Tdt.duration_in_traffic_leg1, ...
    Tdt.duration_leg1); % 28 cols now

% Initialize empty table
nrowsdt = size(Tdt,1);
Tdt_new = cell2table(cell(nrowsdt,22), 'VariableNames', varnames);
Tdt_new.Properties.VariableUnits = varunits;

% Assign old table columns to new
Tdt_new.Origin_name = Tdt.origin;
Tdt_new.Origin_lat = Tdt.start_y_leg1;
Tdt_new.Origin_lon = Tdt.start_x_leg1;
Tdt_new.Destination_name = Tdt.destination;
Tdt_new.Destination_lat = Tdt.end_y_leg1;
Tdt_new.Destination_lon = Tdt.end_x_leg1;
Tdt_new.Date = Tdt.date;
Tdt_new.Day = Tdt.day;
Tdt_new.Local_time = Tdt.time;
Tdt_new.Drive_leg1_distance = Tdt.distance_leg1;
Tdt_new.Drive_leg1_duration = Tdt.duration1;
Tdt_new.Transit_leg2_distance = Tdt.distance_leg2;
Tdt_new.Transit_leg2_duration = Tdt.duration_leg2;

% Set data type for empty numerical columns
nancoldt = NaN(nrowsdt, 1);
Tdt_new.Drive_leg2_distance = nancoldt;
Tdt_new.Drive_leg2_duration = nancoldt;
Tdt_new.Transit_leg1_distance = nancoldt;
Tdt_new.Transit_leg1_duration = nancoldt;
Tdt_new.SplitPt_lat = nancoldt;
Tdt_new.SplitPt_lon = nancoldt;

% Process split points
for i=1:nrowsdt
    tempStr = Tdt.split_point{i};
    if strcmp(tempStr(1),'4') % location is coordinate set
        slashLoc = strfind(tempStr,'/');
        tempLat = str2double(tempStr(1:slashLoc-1));
        tempLon = str2double(tempStr(slashLoc+1:end));
        Tdt_new.SplitPt_lat(i) = tempLat;
        Tdt_new.SplitPt_lon(i) = tempLon;
    else % location is description
        Tdt_new.SplitPt_name{i} = tempStr;
%         Tdt_new.SplitPt_lat(i) = NaN;
%         Tdt_new.SplitPt_lon(i) = NaN;
    end
end

% Binning duration and distance
Tdt_new.Duration_bin = discretize(Tdt_new.Drive_leg1_duration ./ ...
    (Tdt_new.Drive_leg1_duration+Tdt_new.Transit_leg2_duration), 4);
Tdt_new.Distance_bin = discretize(Tdt_new.Drive_leg1_distance ./ ...
    (Tdt_new.Drive_leg1_distance+Tdt_new.Transit_leg2_distance), 4);

%% 4. Process transit -> drive
% Criteria: 
% Col 3 drive_leg = 'finish'
% Col 10 split_point ~= ''
% Col 21 distance_leg2 ~= NaN

Ttd = Tin(strcmp(Tin.drive_leg,'finish') & ...
    ~strcmp(Tin.split_point,'') & ~isnan(Tin.distance_leg2), :);

% Take max of durations for leg 2 driving
Ttd.duration2 = max(Ttd.duration_in_traffic_leg2, ...
    Ttd.duration_leg2); % 28 cols now

% Initialize empty table
nrowstd = size(Ttd,1);
Ttd_new = cell2table(cell(nrowstd,22), 'VariableNames', varnames);
Ttd_new.Properties.VariableUnits = varunits;

% Assign old table columns to new
Ttd_new.Origin_name = Ttd.origin;
Ttd_new.Origin_lat = Ttd.start_y_leg1;
Ttd_new.Origin_lon = Ttd.start_x_leg1;
Ttd_new.Destination_name = Ttd.destination;
Ttd_new.Destination_lat = Ttd.end_y_leg1;
Ttd_new.Destination_lon = Ttd.end_x_leg1;
Ttd_new.Date = Ttd.date;
Ttd_new.Day = Ttd.day;
Ttd_new.Local_time = Ttd.time;
Ttd_new.Transit_leg1_distance = Ttd.distance_leg1;
Ttd_new.Transit_leg1_duration = Ttd.duration_leg1;
Ttd_new.Drive_leg2_distance = Ttd.distance_leg2;
Ttd_new.Drive_leg2_duration = Ttd.duration2;

% Set data type for empty numerical columns
nancoltd = NaN(nrowstd, 1);
Ttd_new.Drive_leg1_distance = nancoltd;
Ttd_new.Drive_leg1_duration = nancoltd;
Ttd_new.Transit_leg2_distance = nancoltd;
Ttd_new.Transit_leg2_duration = nancoltd;
Ttd_new.SplitPt_lat = nancoltd;
Ttd_new.SplitPt_lon = nancoltd;

% Process split points
for i=1:nrowstd
    tempStr = Ttd.split_point{i};
    if strcmp(tempStr(1),'4') % location is coordinate set
        slashLoc = strfind(tempStr,'/');
        tempLat = tempStr(1:slashLoc-1);
        tempLon = tempStr(slashLoc+1:end);
        Ttd_new.SplitPt_lat(i) = str2double(tempLat);
        Ttd_new.SplitPt_lon(i) = str2double(tempLon);
    else % location is description
        Ttd_new.SplitPt_name{i} = tempStr;
%         Ttd_new.SplitPt_lat{i} = NaN;
%         Ttd_new.SplitPt_lon{i} = NaN;
    end
end

% Binning duration and distance
Ttd_new.Duration_bin = discretize(Ttd_new.Drive_leg2_duration ./ ...
    (Ttd_new.Drive_leg2_duration+Ttd_new.Transit_leg1_duration), 4);
Ttd_new.Distance_bin = discretize(Ttd_new.Drive_leg2_distance ./ ...
    (Ttd_new.Drive_leg2_distance+Ttd_new.Transit_leg1_distance), 4);


%% Concatenate and export
Tnew = vertcat(Tdrive_new, Ttransit_new, Tdt_new, Ttd_new);

% Save mat
matname = strcat(targetName, '_xls.mat');
save(matname, 'Tnew');

% Save Excel
xlsname = strcat(targetName, '.xlsx');
writetable(Tnew, xlsname);

disp('Data processing successful');
end