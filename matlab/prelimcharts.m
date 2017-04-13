%% Prelim Charting
% Exploratory charts using NYU_LGA dataset with 4/7 data
clear all; clc; close all;
load data/NYU_LGA.mat
nld = T; clear T; % saved name of table is T

%% Testing color gradients
col1 = [220, 236, 201]; % cyan-green
col2 = [27, 39, 124]; % navy
length = 5;

% test 1: try by varying range
colors = [linspace(col1(1),col2(1),length)', ...
    linspace(col1(2),col2(2),length)', linspace(col1(3),col2(3),length)'];
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

%% Extract Data
dep_times = unique(nld.departure_time);
num = numel(dep_times); % 103 unique times

% Extract driving only trips
tripsDrive = nld(strcmp(nld.mode,'driving'),:);
% 103 results, good

% Extract transit only trips, extract conditions first
transitCond = strcmp(nld.mode,'transit') & ...
    strcmp(nld.split_on_leg,'begin') & ...
    isnan(nld.distance_mi__1); 
tripsTransit = nld(transitCond, :);
% 103 results, good

% Extract all mixed trips
tripsMixed = nld(~isnan(nld.distance_mi__1),:);
% 1378-3*103 = 1069 rows, good
% Maybe put these into 4 bins by proportion of driving to transit for
% plotting?

% Extract all driving -> transit trips
DTCond = strcmp(nld.split_on_leg, 'begin') & ...
    strcmp(nld.drive_leg, 'start');
tripsDT = nld(DTCond, :);
% 829 rows

% Extract all transit -> driving trips
TDCond = strcmp(nld.split_on_leg, 'end') & ...
    strcmp(nld.drive_leg, 'finish');
tripsTD = nld(TDCond, :);
% 240 rows, 240+829 = 1069, good


%% 1. Compare Travel Time Durations
% Chart duration of all driving, all transit, and split trips by time of
% day. Maybe split trips can be put into 4 bins based on proportion of
% distance traveled in driving (darker = more driving), then plot all of
% the TD and DT trips composited.

% Extract relevant data from driving trips
% Columns: 1. dep time, 2. mileage, 3. duration
drive = tripsDrive(:, [9, 11, 15]);
drive.Properties.VariableNames = {'dep_time' 'D_mi' 'D_sec'};
drive.D_min = drive.D_sec ./60;

% Extract relevant data from transit trips
% Columns: 1. dep time, 2. mileage, 3. duration
transit = tripsTransit(:, [9, 11, 15]);
transit.Properties.VariableNames = {'dep_time' 'T_mi' 'T_sec'};
transit.T_min = transit.T_sec ./60;

% Extract relevant data from drive > transit trips
% Columns: 1. dep time, 2. mileage, 3. duration
drtr = tripsDT(:, [9, 11, 15]);
drtr.Properties.VariableNames = {'dep_time' 'T_mi' 'T_sec'};
drtr.T_min = drtr.T_sec ./60;

% Extract relevant data from transit > drive trips
% Columns: 1. dep time, 2. mileage, 3. duration
trdr = tripsTD(:, [9, 11, 15]);
trdr.Properties.VariableNames = {'dep_time' 'T_mi' 'T_sec'};
trdr.T_min = trdr.T_sec ./60;

% Extract relevant data from mixed trips
% Columns: 1. departure time
% 2. Transit mileage, 3. Driving mileage, 4. Transit duration, 5.
% Driving duration
mixed = tripsDT(:, [9, 18, 11, 22, 15]);
mixed = vertcat(mixed, tripsTD(:, [9, 11, 18, 15, 22]));
mixed.Properties.VariableNames = {'dep_time' 'T_mi' 'D_mi' 'T_sec' 'D_sec'};
mixed.T_min = mixed.T_sec ./60;
mixed.D_min = mixed.D_sec ./60;
mixed.propD = mixed.D_mi ./ (mixed.D_mi + mixed.T_mi); % percent driving
mixed.totalTime_min = mixed.T_min + mixed.D_min; 

% Sort into 4 bins
[mixed.bin, edges] = discretize(mixed.propD, 4);

% Bin colors: teal-blue gradient from:
% https://blog.graphiq.com/finding-the-right-color-palettes-for-data-visualizations-fcd4e707a283
ct = [190, 224, 204]./255; % all transit
cb1 = [131, 202, 207] ./255; % bin 1
cb2 = [71, 174, 208] ./255; 
cb3 = [57, 132, 182] ./255;
cb4 = [34, 59, 137] ./255;
cd = [21, 30, 94] ./255; % all driving
ctd = [204, 255, 153] ./255; % transit -> drive, light green
cdt = [127, 0, 255] ./255; % drive -> transit, purp draaaank

% Plots
figure(1)
% driving only
pd = plot(drive.dep_time, drive.D_min, '-', 'LineWidth', 2);
set(pd, 'Color', cd);
title('NYU to LGA Apr 7 Travel Duration')
xlabel('Time of Day')
ylabel('Travel Duration (minutes)')
hold on
% transit only
pt = plot(transit.dep_time, transit.T_min, '-', 'LineWidth', 2);
set(pt, 'Color', ct);
% composite transit > drive
% ptd = plot(trdr.dep_time, trdr.T_min, '-', 'LineWidth', 2);
% set(ptd, 'Color', ctd);
% % composite drive > transit
% pdt = plot(drtr.dep_time, drtr.T_min, '-', 'LineWidth', 2);
% set(pdt, 'Color', cdt);
% composites are wavy and not in a good way, figure out why later
% bin 1
pb1 = plot(mixed.dep_time(mixed.bin == 2,:), ...
    mixed.totalTime_min(mixed.bin == 2, :), '-', 'LineWidth', 2);
set(pb1, 'Color', cb1);
% bin 2
pb2 = plot(mixed.dep_time(mixed.bin == 2,:), ...
    mixed.totalTime_min(mixed.bin == 2, :), '-', 'LineWidth', 2);
set(pb2, 'Color', cb2);
% bin 3
pb3 = plot(mixed.dep_time(mixed.bin == 3,:), ...
    mixed.totalTime_min(mixed.bin == 3, :), '-', 'LineWidth', 2);
set(pb3, 'Color', cb3);
% bin 4
pb4 = plot(mixed.dep_time(mixed.bin == 4,:), ...
    mixed.totalTime_min(mixed.bin == 4, :), '-', 'LineWidth', 2);
set(pb4, 'Color', cb4);
legend('Driving', 'Transit', 'Mixed (0-25% Dr)', 'Mixed (25-50% Dr)', ...
    'Mixed (50-75% Dr)', 'Mixed(75-100% Dr)')





