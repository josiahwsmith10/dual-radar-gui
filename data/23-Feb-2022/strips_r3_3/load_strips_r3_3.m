%% Load Necessary Files
addpath(genpath("./data/ + obj.fileName"))
load("strips_r3_3LoadFiles.mat","scanner")

%% Create Data_Reader
d = Data_Reader(scanner);

%% Load the Scanning Data
d.GetScan();
