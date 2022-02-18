%% Load Necessary Files
addpath(genpath("./data/ + obj.fileName"))
load("empty256_r1LoadFiles.mat","scanner")

%% Create Data_Reader
d = Data_Reader(scanner);

%% Load the Scanning Data
d.GetScan();
