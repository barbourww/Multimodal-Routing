function importNewTripDataMetric(sourceFile, targetFile)
%% Function importNewTripDataMetric
% Import Google Maps trip data from csv. Pipe delimited. Save to
% targetFile; create if it does not exist, append if it does. 
% Export to 'importeddata' folder and leave table in workspace.
% sourceFile NEEDS to be specified in single quotes.
% Assumes sourceFile is in the 'sourcedata' folder

%% Checks
% Check if the targetFile exists, if yes append, if no create new file
fullTFpath = strcat('importeddata/',targetFile);
ex = exist(fullTFpath,'file'); % exist needs to be called separately
if ex == 2 % it exists
    append = 1;
else
    append = 0;
end

fullSFpath = strcat('sourcedata/', sourceFile);
ex2 = exist(fullSFpath,'file'); % exist needs to be called separately
if ex2 ~= 2 % it does not exist
    msg = 'Source file does not exist in sourcedata dir';
    error(msg);
end

% Make sure input is a csv
if sum(fullSFpath(end-2:end) == 'csv') ~= 3
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

T = readtable(fullSFpath, 'Delimiter', '|', 'ReadVariableNames', true, ...
    'Format', '%s%s%s%s%s%s%s%s%s%s%f%f%s%f%f%f%f%f%f%s%f%f%f%f');
% spreadsheet read: T = readtable(sourceFile, 'ReadVariableNames', true);

% Overwrite with correct variable names:
% Original units in comments
correctNames = {'origin'    %1
    'split_on_leg'          %2
    'drive_leg'             %3  
    'avoid'                 %4
    'destination'           %5
    'mode'                  %6
    'units'                 %7
    'timezone'              %8
    'departure_time'        %9
    'split_point'           %10
    'end_y_leg1'            %11
    'end_x_leg1'            %12
    'duration_in_traffic_leg1'  %13, sec
    'distance_leg1'         %14, meters
    'duration_leg1'         %15, sec
    'start_x_leg1'          %16    
    'start_y_leg1'          %17
    'end_y_leg2'            %18
    'end_x_leg2'            %19
    'duration_in_traffic_leg2'  %20, sec
    'distance_leg2'         %21 meters
    'duration_leg2'         %22, sec
    'start_x_leg2'          %23
    'start_y_leg2'};        %24

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
    ''
    ''
    'min'  % originally sec
    'mi'             % originally meters
    'min'             % originally sec
    ''
    ''
    ''
    ''
    'min'  % originally sec
    'mi'             % originally meters
    'min'             % originally sec
    ''
    ''};

T.Properties.VariableNames = correctNames;
T.Properties.VariableUnits = correctUnits;

%% Distance Conversion and Text to Numeric Processing
% Convert from meters to miles
m_to_mi = 0.000621371; % meters to miles conversion
T.distance_leg1 = T.distance_leg1 * m_to_mi;
T.distance_leg2 = T.distance_leg2 * m_to_mi;

% Change units
T.units = replace(T.units, 'metric', 'imperial');

%% Duration in Traffic Conversion and Text to Numeric Processing
% Convert from seconds to minutes
dit1_txt = T.duration_in_traffic_leg1;
dit2_txt = T.duration_in_traffic_leg2;
dit1_num = NaN(size(dit1_txt)); % Initialize numeric vectors
dit2_num = NaN(size(dit2_txt));

for i = 1:size(dit1_txt, 1)
    tempVal1 = char(dit1_txt(i));
    if strcmp(tempVal1, '')
        dit1_num(i) = NaN;
    elseif strcmp(tempVal1, 'n/a')
        dit1_num(i) = NaN;
    else
        dit1_num(i) = str2double(tempVal1) /60; % to minutes
    end
    
    tempVal2 = char(dit2_txt(i));
    if strcmp(tempVal2, '')
        dit2_num(i) = NaN;
    elseif strcmp(tempVal2, 'n/a')
        dit2_num(i) = NaN;
    else
        dit2_num(i) = str2double(tempVal2) /60; % to minutes
    end
end

T.duration_in_traffic_leg1 = dit1_num;
T.duration_in_traffic_leg2 = dit2_num;

% Convert non-text durations to minutes
T.duration_leg1 = T.duration_leg1 ./60;
T.duration_leg2 = T.duration_leg2 ./60;

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
    disp('Import successful');
end

end