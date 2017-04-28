%% Travel Time Variance Analysis
% Variance analysis using CHI_ORD dataset to start.
% For each time of day, look at all observations on 15 min either side.
% Different analyses for each day of week, plus combined wkend and wkdays.
% Fit distribution and get parameters.

clear; clc; close all;
load processeddata\CHI_ORD_xls.mat
% table is called Tnew

%% Exploratory plot of all data for drive only
i = 6; % saturday
tempData = Tnew(Tnew.Day ~= i,:); % weekdays
% Not enough data points to analyze one weekday at a time, so do weekdays

dataDriveOnly = tempData(isnan(tempData.Duration_bin) & ...
    isnan(tempData.Transit_leg1_duration),[12 14]);
dataDriveOnly.Local_time = datetime(dataDriveOnly.Local_time);
% datetime here sets the date to the current date, but only need the time
% element of it.
% durationDriveOnly = table2array(tempData(isnan(tempData.Duration_bin) & ...
%    isnan(tempData.Transit_leg1_duration),14));

% Drive only
figure(1)
scatter(dataDriveOnly.Local_time,dataDriveOnly.Drive_leg1_duration, ...
    'filled')
xlabel('Time of Day')
ylabel('Travel duration (min)')
title('UChicago to ORD: Duration vs. Time of Day (weekdays)')


%% Plot distributions for departure time
numTimes = numel(dataDriveOnly.Local_time); %353
sortedTimes = unique(sort(dataDriveOnly.Local_time));
numUniqueTimes = numel(sortedTimes); %137

timeWindow = 15/60/24; % 15 min

sampleSumStats = cell2table(cell(0,2));

figure(2)
ctr = 1;
for t = 1:10:floor(numUniqueTimes/2)
    tempTime = sortedTimes(t);
    data30min = dataDriveOnly(...
        (dataDriveOnly.Local_time >= tempTime - timeWindow) & ...
        (dataDriveOnly.Local_time <= tempTime + timeWindow), :);
    subplot(4, 2, ctr)
    histogram(data30min.Drive_leg1_duration,20)
    title(datestr(tempTime))
    tempTimes(ctr) = tempTime;
    sampleSumStats{ctr,1} = mean(data30min.Drive_leg1_duration);
    sampleSumStats{ctr,2} = sqrt(var(data30min.Drive_leg1_duration));
    ctr = ctr + 1;
end

figure(3)
ctr2 = 1;
for t = ceil(numUniqueTimes/2):10:numUniqueTimes
    tempTime = sortedTimes(t);
    data30min = dataDriveOnly(...
        (dataDriveOnly.Local_time >= tempTime - timeWindow) & ...
        (dataDriveOnly.Local_time <= tempTime + timeWindow), :);
    subplot(4, 2, ctr2)
    histogram(data30min.Drive_leg1_duration,20)
    title(datestr(tempTime))
    tempTimes(ctr+ctr2) = tempTime;
    sampleSumStats{ctr+ctr2,1} = mean(data30min.Drive_leg1_duration);
    sampleSumStats{ctr+ctr2,2} = sqrt(var(data30min.Drive_leg1_duration));
    ctr2 = ctr2 + 1;
end

sampleSumStats.Properties.VariableNames = {'Mean', 'SD'};
sampleSumStats.Time = tempTimes';



%% below this is old from durationcharts.m
%--------------------------------------------------
%--------------------------------------------------
%--------------------------------------------------
%--------------------------------------------------

%% Extract Data for Each Mode
depTimes = unique(nld.departure_time);
num = numel(depTimes); % 103 unique times

% Extract driving only trips
dataDrive = nld(strcmp(nld.mode,'driving'),:);
% 103 results, good

% Extract transit only trips, extract conditions first
transitCond = strcmp(nld.mode,'transit') & ...
    strcmp(nld.split_on_leg,'begin') & ...
    isnan(nld.distance_leg2); 
dataTransit = nld(transitCond, :);
% 103 results, good

% Extract all mixed trips
dataMixed = nld(~isnan(nld.distance_leg2),:);
% 1378-3*103 = 1069 rows, good
% Maybe put these into 4 bins by proportion of driving to transit for
% plotting?

% Extract all driving -> transit trips
DTCond = strcmp(nld.split_on_leg, 'begin') & ...
    strcmp(nld.drive_leg, 'start');
dataDT = nld(DTCond, :);
% 829 rows

% Extract all transit -> driving trips
TDCond = strcmp(nld.split_on_leg, 'end') & ...
    strcmp(nld.drive_leg, 'finish');
dataTD = nld(TDCond, :);
% 240 rows, 240+829 = 1069, good


%% Duration Trip Data Processing

% Extract relevant data from driving trips
% Columns: 1. dep time, 2. mileage, 3. duration in traffic 4. duration
% Duration units are in seconds, need to convert to minutes.
% Also convert depTime from datetime to integer value 0-24 hrs
% For driving, use duration_in_traffic. duration is just free-flow time.
% For transit, use 
tripsDrive = dataDrive(:, [9, 11, 14, 15]);
tripsDrive.Properties.VariableNames = {'depTime' 'distD' ...
    'timeTraffic_sec' 'timeFreeFlow_sec'};
tripsDrive.timeTraffic_min = tripsDrive.timeTraffic_sec ./60;
tripsDrive.timeFreeFlow_min = tripsDrive.timeFreeFlow_sec ./60;
tripsDrive.timeDrive_min = max(tripsDrive.timeTraffic_min, ...
    tripsDrive.timeFreeFlow_min);
tempDV = datevec(tripsDrive.depTime);
tripsDrive.depTimeHr = tempDV(:,4) + tempDV(:,5)./60 + tempDV(:,6)./60^2;

% Extract relevant data from transit trips
tripsTransit = dataTransit(:, [9, 11, 15]);
tripsTransit.Properties.VariableNames = {'depTime' 'distT' ...
    'timeTransit_sec'};
tripsTransit.timeTransit_min = tripsTransit.timeTransit_sec ./60;
tempDV = datevec(tripsTransit.depTime);
tripsTransit.depTimeHr = tempDV(:,4) + tempDV(:,5)./60 + tempDV(:,6)./60^2;

% Extract relevant data from drive > transit trips
% Composite time & distance for all drive > transit trips
tripsDT = dataDT(:, [9, 11, 14, 15, 18, 22]);
tripsDT.Properties.VariableNames = {'depTime' 'distD' ...
    'timeTraffic_sec' 'timeFreeFlow_sec' 'distT' 'timeTransit_sec'};
tripsDT.distTot_mi = tripsDT.distD + tripsDT.distT;
tripsDT.timeTransit_min = tripsDT.timeTransit_sec ./60;
tripsDT.timeTraffic_min = tripsDT.timeTraffic_sec ./60;
tripsDT.timeFreeFlow_min = tripsDT.timeFreeFlow_sec ./60;
tripsDT.timeDrive_min = max(tripsDT.timeTraffic_min, tripsDT.timeFreeFlow_min);
tempDV = datevec(tripsDT.depTime);
tripsDT.depTimeHr = tempDV(:,4) + tempDV(:,5)./60 + tempDV(:,6)./60^2;
tripsDT.timeTotal_min = tripsDT.timeDrive_min + tripsDT.timeTransit_min;

% Extract relevant data from transit > drive trips
% Composite time & distance for all transit > drive trips
tripsTD = dataTD(:, [9, 11, 15, 18, 21, 22]);
tripsTD.Properties.VariableNames = {'depTime' 'distT' ...
    'timeTransit_sec' 'distD' 'timeTraffic_sec' 'timeFreeFlow_sec'};
tripsTD.distTot_mi = tripsTD.distD + tripsTD.distT;
tripsTD.timeTransit_min = tripsTD.timeTransit_sec ./60;
tripsTD.timeTraffic_min = tripsTD.timeTraffic_sec ./60;
tripsTD.timeFreeFlow_min = tripsTD.timeFreeFlow_sec ./60;
tripsTD.timeDrive_min = max(tripsTD.timeTraffic_min, tripsTD.timeFreeFlow_min);
tempDV = datevec(tripsTD.depTime);
tripsTD.depTimeHr = tempDV(:,4) + tempDV(:,5)./60 + tempDV(:,6)./60^2;
tripsTD.timeTotal_min = tripsTD.timeDrive_min + tripsTD.timeTransit_min;

% Extract relevant data from mixed trips
% Columns: 1. departure time, 2. Transit mileage
% 3. Driving mileage, 4. Transit duration, 
% 5. Driving duration traffic, 6. driving duration freeflow
tripsMixed1 = dataDT(:, [9, 18, 11, 22, 14, 15]);
tripsMixed1.Properties.VariableNames = {'depTime' 'distT' 'distD' ...
    'timeTransit_sec', 'timeTraffic_sec', 'timeFreeFlow_sec'};
tripsMixed2 = dataTD(:, [9, 11, 18, 15, 21, 22]);
tripsMixed2.Properties.VariableNames = {'depTime' 'distT' 'distD' ...
    'timeTransit_sec', 'timeTraffic_sec', 'timeFreeFlow_sec'};
tripsMixed = vertcat(tripsMixed1, tripsMixed2); 

tripsMixed.timeTransit_min = tripsMixed.timeTransit_sec ./60;
tripsMixed.timeDrive_min = max(tripsMixed.timeTraffic_sec, ...
    tripsMixed.timeFreeFlow_sec) ./60;
tripsMixed.timeTotal_min = tripsMixed.timeDrive_min + ...
    tripsMixed.timeTransit_min;

% Calculate proportion of driving time in total travel time
tripsMixed.propD = tripsMixed.timeDrive_min ./ ...
    tripsMixed.timeTotal_min;
% Sort into 4 bins
[tripsMixed.bin, edges] = discretize(tripsMixed.propD, 4);

tempDV = datevec(tripsMixed.depTime);
tripsMixed.depTimeHr = tempDV(:,4) + tempDV(:,5)./60 + tempDV(:,6)./60^2;


%% Plot 1: Scatter: driving & transit only, plus composites
% Bin colors: 
% https://blog.graphiq.com/finding-the-right-color-palettes-for-data-visualizations-fcd4e707a283
colors = NaN(8,3);
colors(1,:) = [190, 224, 204]./255; % all transit
colors(2,:) = [255, 255, 162] ./255; % bin 1
colors(3,:) = [190, 235, 159] ./255; % bin 2
colors(4,:) = [121, 189, 143] ./255; % bin 3
colors(5,:) = [0, 162, 136] ./255; % bin 4
colors(6,:) = [21, 30, 94] ./255; % all driving
colors(7,:) = [204, 255, 153] ./255; % transit -> drive, light green
colors(8,:) = [127, 0, 255] ./255; % drive -> transit, purp
% Gradient is not super visible ... 

figure(1)
% driving only
pd = plot(tripsDrive.depTimeHr, tripsDrive.timeDrive_min, 'o', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'k', 'MarkerSize', 3);
title('NYU to LGA Apr 7 Travel Duration')
xlabel('Time of Day')
ylabel('Travel Duration (minutes)')
hold on
% transit only
pt = plot(tripsTransit.depTimeHr, tripsTransit.timeTransit_min, 'o', ...
    'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'r', 'MarkerSize', 3);
% composite transit > drive
ptd = plot(tripsTD.depTimeHr, tripsTD.timeTotal_min, 'o', ...
    'MarkerEdgeColor', 'g', 'MarkerFaceColor', 'g', 'MarkerSize', 3);
% composite drive > transit
pdt = plot(tripsDT.depTimeHr, tripsDT.timeTotal_min, 'o', ...
    'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'b', 'MarkerSize', 3);
legend('Driving', 'Transit', 'Composite Trans -> Dr', ...
    'Composite Dr -> Transit')

%% Plot 2: scatter of the four mixed bins

figure(2)
% bin 1
pb1 = plot(tripsMixed.depTimeHr(tripsMixed.bin == 1,:), ...
    tripsMixed.timeTotal_min(tripsMixed.bin == 1, :), 'o', ...
    'MarkerEdgeColor', colors(2,:), 'MarkerFaceColor', colors(2,:), 'MarkerSize', 4);
hold on
% bin 2
pb2 = plot(tripsMixed.depTimeHr(tripsMixed.bin == 2,:), ...
    tripsMixed.timeTotal_min(tripsMixed.bin == 2, :), 'o', ...
    'MarkerEdgeColor', colors(3,:), 'MarkerFaceColor', colors(3,:), 'MarkerSize', 4);
% bin 3
pb3 = plot(tripsMixed.depTimeHr(tripsMixed.bin == 3,:), ...
    tripsMixed.timeTotal_min(tripsMixed.bin == 3, :), 'o', ...
    'MarkerEdgeColor', colors(4,:), 'MarkerFaceColor', colors(4,:), 'MarkerSize', 4);
% bin 4
pb4 = plot(tripsMixed.depTimeHr(tripsMixed.bin == 4,:), ...
    tripsMixed.timeTotal_min(tripsMixed.bin == 4, :), 'o', ...
    'MarkerEdgeColor', colors(5,:), 'MarkerFaceColor', colors(5,:), 'MarkerSize', 4);
title('NYU to LGA Apr 7 Travel Duration')
xlabel('Time of Day')
ylabel('Travel Duration (minutes)')
legend('Mixed (0-25% Dr)', 'Mixed (25-50% Dr)', ...
    'Mixed (50-75% Dr)', 'Mixed (75-100% Dr)')
