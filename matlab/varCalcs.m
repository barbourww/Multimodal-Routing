%% Travel Time Mean & Variance Calculations
clear; clc; close all;
load processeddata\ORD_CUB_xls.mat

%% Extract datasets for each mode choice
% Separate weekday and weekend
wdData = Tnew(Tnew.Day ~= 1 & Tnew.Day ~= 7, :); % weekday
weData = Tnew(Tnew.Day == 1 | Tnew.Day == 7, :); % weekend
% no weekend data for CHI_ORD, DCA_UMD, HAR_BOS, IAD_GTU, NYU_LGA, ORD_CUB

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

driveSumStats.Properties.VariableNames = {'Mean_drive', 'SD_drive'};
driveSumStats.TimeDrive = tempTimes';

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

transitSumStats.Properties.VariableNames = {'Mean_transit', 'SD_transit'};
transitSumStats.TimeTransit = tempTimes';

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

DTSumStats.Properties.VariableNames = {'Mean_DT', 'SD_DT'};
DTSumStats.TimeDT = tempTimes';

%% Mean and SD Calculations - 4. Transit -> Drive
sortTimeTD = unique(sort(wdTD.Local_time));
numTimeTD = numel(sortTimeTD);

TDSumStats = cell2table(cell(0,2));

for t = 1:numTimeTD
    tempTime = sortTimeTD(t);
    tempData = wdTD(...
        (wdTD.Local_time >= tempTime - timeWindow) & ...
        (wdTD.Local_time <= tempTime + timeWindow), :);
    TDSumStats(t,:) = {mean(tempData.Trip_duration) ...
        sqrt(var(tempData.Trip_duration))};
    tempTimes(t) = tempTime;
end

TDSumStats.Properties.VariableNames = {'Mean_TD', 'SD_TD'};
TDSumStats.TimeTD = tempTimes';

%% Merge
% all unique times were the same, so just combine.
ORD_CUB_SumStats = horzcat(driveSumStats, transitSumStats, DTSumStats, ...
    TDSumStats);

% Get rid of extra columns
ORD_CUB_SumStats.TimeTransit = [];
ORD_CUB_SumStats.TimeDT = [];
ORD_CUB_SumStats.TimeTD = [];
ORD_CUB_SumStats = [ORD_CUB_SumStats(:,3) ORD_CUB_SumStats(:,1:2) ...
    ORD_CUB_SumStats(:,4:end)];
ORD_CUB_SumStats.Properties.VariableNames(1) = {'Time'};

%% Export
% Save mat
save('ORD_CUB_sumstats.mat', 'ORD_CUB_SumStats');

% Save Excel
xlsname = 'ORD_CUB_SumStats.xlsx';
writetable(ORD_CUB_SumStats, xlsname);




