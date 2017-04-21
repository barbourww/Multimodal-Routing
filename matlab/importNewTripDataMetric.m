function importNewTripDataMetric(sourceFile, targetFile)
%% Function importNewTripDataMetric
% Import Google Maps trip data from csv. Pipe delimited. Save to
% targetFile; create if it does not exist, append if it does. 
% Export to 'data' folder and leave table in workspace.
% sourceFile NEEDS to be specified in single quotes.

%% Checks
% Check if the targetFile exists, if yes append, if no create new file
fullTFpath = strcat('data/',targetFile);
ex = exist(fullTFpath,'file'); % exist needs to be called separately
if ex == 2 % it exists
    append = 1;
else
    append = 0;
end

% Make sure input is a csv
if sum(sourceFile(end-2:end) == 'csv') ~= 3
    msg = 'sourceFile is not a csv file';
    error(msg);
end

%% Import
% 24 data columns. Note that column order was reorganized from original
% imperial unit column order.

% Notes:
% The two duration_in_traffic_sec columns are imported as string
% since "n/a" values are present. These are replaced by blanks then
% converted to numeric.

T = readtable(sourceFile, 'Delimiter', '|', 'ReadVariableNames', true, ...
    'Format', '%s%s%s%s%s%s%s%s%s%s%f%f%f%s%f%f%f%f%f%f%s%f%f%f');
% spreadsheet read: T = readtable(sourceFile, 'ReadVariableNames', true);

% Overwrite with correct variable names:
correctNames = {'origin'
    'split_on_leg'
    'drive_leg'
    'avoid'
    'destination'
    'mode'
    'units'
    'timezone'
    'departure_time'
    'split_point'
    'distance_leg1'             % originally meters
    'end_y_leg1'
    'end_x_leg1'
    'duration_in_traffic_leg1'  % sec
    'duration_leg1'             % sec
    'start_x_leg1'
    'start_y_leg1'
    'distance_leg2'             % originally meters
    'end_y_leg2'
    'end_x_leg2'
    'duration_in_traffic_leg2'  % sec
    'duration_leg2'             % sec
    'start_x_leg2'
    'start_y_leg2'};

correctUnits = {''
    ''
    ''
    ''
    ''
    ''
    ''
    ''
    ''
    ''
    'mi'  % originally meters
    ''
    ''
    'sec'
    'sec'
    ''
    ''
    'mi'  % originally meters
    ''
    ''
    'sec'
    'sec'
    ''
    ''};

T.Properties.VariableNames = correctNames;
T.Properties.VariableUnits = correctUnits;

%% Distance Conversion and Text to Numeric Processing
% Convert from meters to miles
dist_txt = T.distance_mi_leg1;
dist_1_txt = T.distance_mi_leg2;
dist_num = NaN(size(dist_txt)); % Initialize numeric vectors
dist_1_num = NaN(size(dist_1_txt));

for i = 1:size(dist_txt, 1)
    tempVal = char(dist_txt(i));
    if isempty(tempVal)
        dist_num(i) = NaN;
    elseif tempVal(end-1:end) == 'mi'
        dist_num(i) = str2double(tempVal(1:end-3));
    elseif tempVal(end-1:end) == 'ft'
        dist_num(i) = str2double(tempVal(1:end-3)) / 5280;
    end
    
    tempVal_1 = char(dist_1_txt(i));
    if isempty(tempVal_1)
        dist_1_num(i) = NaN;
    elseif tempVal_1(end-1:end) == 'mi'
        dist_1_num(i) = str2double(tempVal_1(1:end-3));
    elseif tempVal_1(end-1:end) == 'ft'
        dist_1_num(i) = str2double(tempVal_1(1:end-3)) / 5280;
    end 
end

T.distance_mi_leg1 = dist_num;
T.distance_mi_leg2 = dist_1_num;

clear dist_txt dist_1_txt dist_num dist_1_num

%% Duration in Traffic Conversion and Text to Numeric Processing
dit_txt = T.duration_in_traffic_sec_leg1;
dit_1_txt = T.duration_in_traffic_sec_leg2;
dit_num = NaN(size(dit_txt)); % Initialize numeric vectors
dit_1_num = NaN(size(dit_1_txt));

for i = 1:size(dit_txt, 1)
    tempVal = char(dit_txt(i));
    if strcmp(tempVal, '')
        dit_num(i) = NaN;
    elseif strcmp(tempVal, 'n/a')
        dit_num(i) = NaN;
    else
        dit_num(i) = str2double(tempVal);
    end
    
    tempVal_1 = char(dit_1_txt(i));
    if strcmp(tempVal_1, '')
        dit_1_num(i) = NaN;
    elseif strcmp(tempVal_1, 'n/a')
        dit_1_num(i) = NaN;
    else
        dit_1_num(i) = str2double(tempVal_1);
    end
end

T.duration_in_traffic_sec_leg1 = dit_num;
T.duration_in_traffic_sec_leg2 = dit_1_num;

clear dit_txt dit_1_txt dit_num dit_1_num

%% Date Time Processing
% Departure time is column 9. Format into 'datetime' format.
tz_txt = T{1,8}; % timezone is in column 8

% Manually get into IANA format... not sure if there's a better way
if tz_txt{1} == 'eastern'
    tz = 'America/New_York';
elseif tz_txt{1} == 'central'
    tz = 'America/Chicago';
elseif tz_txt{1} == 'mountain'
    tz = 'America/Denver';
elseif tz_txt{1} == 'pacific'
    tz = 'America/Los_Angeles';
end

% Remove '-05:00' from the end of departure time
tempDT = replace(T.departure_time,"-05:00","");

% Format to datetime
tempDT = datetime(tempDT, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');

% Times are in Central, so convert to specified time zone and tag datetime
% with the time dzone
if strcmp(tz,'America/New_York')
    tempDT = tempDT + 1/24; % add one hour
    tempDT.TimeZone = tz;
elseif strcmp(tz,'America/Chicago')
    tempDT.TimeZone = tz;
elseif strcmp(tz,'America/Denver')
    tempDT = tempDT - 1/24;
    tempDT.TimeZone = tz;
elseif strcmp(tz,'America/Los_Angeles')
    tempDT = tempDT - 2/24;
    tempDT.TimeZone = tz;
end

% Replace column in table 
T.departure_time = tempDT;

%% Save and Append
if append == 0
    save(fullTFpath, 'T');
elseif append == 1
    % load original file
    T_curr = T; % just for storage
    T_old = load(fullTFpath); % loaded as a struct
    T = vertcat(T_old.T, T);
    save(fullTFpath, 'T');
end

end