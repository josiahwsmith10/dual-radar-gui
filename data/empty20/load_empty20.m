%% Load Necessary Files
load("empty20LoadFiles.mat","scanner")

%% Create Data_Reader
d = Data_Reader(scanner);

%% Load the Scanning Data
d.GetScan();
