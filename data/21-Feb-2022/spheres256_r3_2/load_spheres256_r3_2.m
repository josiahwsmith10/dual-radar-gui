%% Load Necessary Files
addpath(genpath("./data/ + obj.fileName"))
load("spheres256_r3_2LoadFiles.mat","scanner")

%% Create Data_Reader
d = Data_Reader(scanner);

%% Load the Scanning Data
d.GetScan();
