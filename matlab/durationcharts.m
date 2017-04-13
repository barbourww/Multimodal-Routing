%% Duration Charts
% Exploratory charts using NYU_LGA dataset with 4/7 data.
% Expected travel duration vs. time of day for different mode combos.
% Chart duration of all driving, all transit, and split trips by time of
% day. Maybe split trips can be put into 4 bins based on proportion of
% distance traveled in driving (darker = more driving), then plot all of
% the TD and DT trips composited.
clear all; clc; close all;
load data/NYU_LGA.mat
nld = T; clear T; % saved name of table is T

%% Testing color gradients
% col1 = [220, 236, 201]; % cyan-green
% col2 = [27, 39, 124]; % navy
% length = 5;
% 
% % test 1: try by varying range
% colors = [linspace(col1(1),col2(1),length)', ...
%     linspace(col1(2),col2(2),length)', linspace(col1(3),col2(3),length)'];
% test plot
% S=10;   % marker size
% testx = linspace(0,100,length);
% testy = log(testx);
% figure
% plot(testx(1), testy(1), 'o','MarkerEdgeColor','k','MarkerFaceColor',colors(1,:),'markersize',S);
% hold on
% plot(testx(2), testy(2), 'o','MarkerEdgeColor','k','MarkerFaceColor',colors(2,:),'markersize',S);
% plot(testx(3), testy(3), 'o','MarkerEdgeColor','k','MarkerFaceColor',colors(3,:),'markersize',S);
% plot(testx(4), testy(4), 'o','MarkerEdgeColor','k','MarkerFaceColor',colors(4,:),'markersize',S);
% plot(testx(5), testy(5), 'o','MarkerEdgeColor','k','MarkerFaceColor',colors(5,:),'markersize',S);
% Not a huge fan of the colors need to play with this some more.
% Can always manually define colors but I would expect the number of trips
% to vary quite a bit... 

% test 2: use colorGradient function from matlab file exchange
% grad = colorGradient(col1,col2,length);
% figure
% surf(peaks)
% colormap(grad);
% this is a bit better so I'll try this.

%% Extract Data for Each Mode
depTimes = unique(nld.departure_time);
num = numel(depTimes); % 103 unique times

% Extract driving only trips
dataDrive = nld(strcmp(nld.mode,'driving'),:);
% 103 results, good

% Extract transit only trips, extract conditions first
transitCond = strcmp(nld.mode,'transit') & ...
    strcmp(nld.split_on_leg,'begin') & ...
    isnan(nld.distance_mi__1); 
dataTransit = nld(transitCond, :);
% 103 results, good

% Extract all mixed trips
dataMixed = nld(~isnan(nld.distance_mi__1),:);
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
tripsDrive = dataDrive(:, [9, 11, 14, 15]);
tripsDrive.Properties.VariableNames = {'depTime' 'distD_mi' ...
    'timeTraffic_sec' 'timeFreeFlow_sec'};
tripsDrive.timeTotal_min = (tripsDrive.timeTraffic_sec + ...
    tripsDrive.timeFreeFlow_sec) ./60;
tempDV = datevec(tripsDrive.depTime);
tripsDrive.depTimeHr = tempDV(:,4) + tempDV(:,5)./60 + tempDV(:,6)./60^2;

% Extract relevant data from transit trips
tripsTransit = dataTransit(:, [9, 11, 15]);
tripsTransit.Properties.VariableNames = {'depTime' 'distT_mi' ...
    'timeTransit_sec'};
tripsTransit.timeTransit_min = tripsTransit.timeTransit_sec ./60;
tempDV = datevec(tripsTransit.depTime);
tripsTransit.depTimeHr = tempDV(:,4) + tempDV(:,5)./60 + tempDV(:,6)./60^2;

% Extract relevant data from drive > transit trips
% Composite time & distance for all drive > transit trips
tripsDT = dataDT(:, [9, 11, 14, 15, 18, 22]);
tripsDT.Properties.VariableNames = {'depTime' 'distD_mi' ...
    'timeTraffic_sec' 'timeFreeFlow_sec' 'distT_mi' 'timeTransit_sec'};
tripsDT.distTot_mi = tripsDT.distD_mi + tripsDT.distT_mi;
tripsDT.timeTotal_min = (tripsDT.timeTraffic_sec + ...
    tripsDT.timeFreeFlow_sec + tripsDT.timeTransit_sec) ./60;
tempDV = datevec(tripsDT.depTime);
tripsDT.depTimeHr = tempDV(:,4) + tempDV(:,5)./60 + tempDV(:,6)./60^2;

% Extract relevant data from transit > drive trips
% Composite time & distance for all transit > drive trips
tripsTD = dataTD(:, [9, 11, 15, 18, 21, 22]);
tripsTD.Properties.VariableNames = {'depTime' 'distT_mi' ...
    'timeTransit_sec' 'distD_mi' 'timeTraffic_sec' 'timeFreeFlow_sec'};
tripsTD.timeTotal_min = (tripsTD.timeTraffic_sec + ...
    tripsTD.timeFreeFlow_sec + tripsTD.timeTransit_sec) ./60;
tempDV = datevec(tripsTD.depTime);
tripsTD.depTimeHr = tempDV(:,4) + tempDV(:,5)./60 + tempDV(:,6)./60^2;

% Extract relevant data from mixed trips
% Columns: 1. departure time, 2. Transit mileage
% 3. Driving mileage, 4. Transit duration, 
% 5. Driving duration traffic, 6. driving duration freeflow
tripsMixed1 = dataDT(:, [9, 18, 11, 22, 14, 15]);
tripsMixed1.Properties.VariableNames = {'depTime' 'distT_mi' 'distD_mi' ...
    'timeTransit_sec', 'timeTraffic_sec', 'timeFreeFlow_sec'};
tripsMixed2 = dataTD(:, [9, 11, 18, 15, 21, 22]);
tripsMixed2.Properties.VariableNames = {'depTime' 'distT_mi' 'distD_mi' ...
    'timeTransit_sec', 'timeTraffic_sec', 'timeFreeFlow_sec'};
tripsMixed = vertcat(tripsMixed1, tripsMixed2);

tripsMixed.timeTransit_min = tripsMixed.timeTransit_sec ./60;
tripsMixed.timeTotal_min = (tripsMixed.timeTraffic_sec + ...
    tripsMixed.timeFreeFlow_sec + tripsMixed.timeTransit_sec) ./60;

% Calculate proportion of driving time in total travel time
tripsMixed.propD = 1 - (tripsMixed.timeTransit_min ./ ...
    tripsMixed.timeTotal_min);
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
pd = plot(tripsDrive.depTimeHr, tripsDrive.timeTotal_min, 'o', ...
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
