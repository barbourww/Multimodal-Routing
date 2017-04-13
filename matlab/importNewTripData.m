function importNewTripData(sourceFile, targetFile)
%% Function importNewTripData
% Import Google Maps trip data from csv. Pipe delimited. Save to
% targetFile; create if it does not exist, append if it does. 
% Export to 'data' folder and leave table in workspace.
% sourceFile NEEDS to be specified in single quotes

%% Checks
% Check if the targetFile exists, if yes append, if no create new file
fullTFpath = strcat('data/',targetFile);
ex = exist(fullTFpath); % exist needs to be called separately apparently
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
% 24 data columns. First 10 are imported as string, last 14 as fixed point
T = readtable(sourceFile, 'Delimiter', '|', 'ReadVariableNames', true, ...
    'Format', '%s%s%s%s%s%s%s%s%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
% spreadsheet read: T = readtable(sourceFile, 'ReadVariableNames', true);

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
if tz == 'America/New_York'
    tempDT = tempDT + 1/24; % add one hour
    tempDT.TimeZone = tz;
elseif tz == 'America/Chicago'
    tempDT.TimeZone = tz;
elseif tz == 'America/Denver'
    tempDT = tempDT - 1/24;
    tempDT.TimeZone = tz;
elseif tz == 'America/Los_Angeles'
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
    T_old = load(fullTFpath); % loaded as a struct
    T_new = vertcat(T_old.T, T);
    save(fullTFpath, 'T_new');
end

end