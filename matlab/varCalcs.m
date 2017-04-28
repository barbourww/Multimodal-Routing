%% Travel Time Mean & Variance Calculations
clear; clc; close all;
load processeddata\CHI_ORD_xls.mat

%% Extract datasets for each mode choice
% Separate weekday and weekend
wdData = Tnew(Tnew.Day ~= 1 | Tnew.Day ~= 7, :); % weekday
weData = Tnew(Tnew.Day == 1 | Tnew.Day == 7, :); % weekend
% no weekend data for Chicago

% 1. Driving only
wdDrive = wdData(isnan(wdData.Duration_bin) & ...
    isnan(wdData.Transit_leg1_duration),[12 14]);
wdDrive.Local_time = datetime(wdDrive.Local_time);
% datetime here sets the date to the current date, but only need the time
% element of it.

% 2. Transit only
wdTransit = wdData(isnan(wdData.Duration_bin) & ...
    isnan(wdData.Drive_leg1_duration),[12 16]);
wdTransit.Local_time = datetime(wdTransit.Local_time);

% 3. Drive -> transit
wdDT = wdData(~isnan(wdData.Drive_leg1_duration) & ...
    ~isnan(wdData.Transit_leg2_duration),[12 14 20]);
wdDT.Local_time = datetime(wdDT.Local_time);
wdDT.Trip_duration = wdDT.Drive_leg1_duration + wdDT.Transit_leg2_duration;

% 4. Transit -> Drive
wdTD = wdData(~isnan(wdData.Drive_leg2_duration) & ...
    ~isnan(wdData.Transit_leg1_duration),[12 16 18]);
wdTD.Local_time = datetime(wdTD.Local_time);
wdTD.Trip_duration = wdTD.Drive_leg2_duration + wdTD.Transit_leg1_duration;

% Row add up to total, all good.

%% Mean and SD Calculations - 1. Drive
timeWindow = 15/60/24; % 15 min on either side

% Get unique departure times
sortTimeDrive = unique(sort(wdDrive.Local_time));
numTimeDrive = numel(sortTimeDrive);

driveSumStats = cell2table(cell(0,2));

for t = 1:numTimeDrive
    tempTime = sortTimeDrive(t);
    tempData = wdDrive(...
        (wdDrive.Local_time >= tempTime - timeWindow) & ...
        (wdDrive.Local_time <= tempTime + timeWindow), :);
    driveSumStats(t,:) = {mean(tempData.Drive_leg1_duration) ...
        sqrt(var(tempData.Drive_leg1_duration))};
    tempTimes(t) = tempTime;
end

driveSumStats.Properties.VariableNames = {'Mean', 'SD'};
driveSumStats.Time = tempTimes';

%% Mean and SD Calculations - 2. Transit
% Get unique departure times
sortTimeTransit = unique(sort(wdTransit.Local_time));
numTimeTransit = numel(sortTimeTransit);

transitSumStats = cell2table(cell(0,2));

for t = 1:numTimeTransit
    tempTime = sortTimeTransit(t);
    tempData = wdTransit(...
        (wdTransit.Local_time >= tempTime - timeWindow) & ...
        (wdTransit.Local_time <= tempTime + timeWindow), :);
    transitSumStats(t,:) = {mean(tempData.Transit_leg1_duration) ...
        sqrt(var(tempData.Transit_leg1_duration))};
    tempTimes(t) = tempTime;
end

transitSumStats.Properties.VariableNames = {'Mean', 'SD'};
transitSumStats.Time = tempTimes';

%% Mean and SD Calculations - 3. Drive -> Transit
sortTimeDT = unique(sort(wdDT.Local_time));
numTimeDT = numel(sortTimeDT);

DTSumStats = cell2table(cell(0,2));

for t = 1:numTimeDT
    tempTime = sortTimeDT(t);
    tempData = wdDT(...
        (wdDT.Local_time >= tempTime - timeWindow) & ...
        (wdDT.Local_time <= tempTime + timeWindow), :);
    DTSumStats(t,:) = {mean(tempData.Trip_duration) ...
        sqrt(var(tempData.Trip_duration))};
    tempTimes(t) = tempTime;
end

DTSumStats.Properties.VariableNames = {'Mean', 'SD'};
DTSumStats.Time = tempTimes';

%% Mean and SD Calculations - 4. Transit -> Drive
sortTimeTD = unique(sort(wdTD.Local_time));

