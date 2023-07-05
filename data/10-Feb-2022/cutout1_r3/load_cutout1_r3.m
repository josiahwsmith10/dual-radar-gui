%% Load Necessary Files
addpath(genpath("./data/ + obj.fileName"))
load("cutout1_r3LoadFiles.mat","scanner")

%% Create Data_Reader
d = Data_Reader(scanner);

%% Load the Scanning Data
d.GetScan();
