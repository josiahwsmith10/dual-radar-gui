%% Load Necessary Files
load(cd + "\data\" + obj.fileName + "\" + obj.fileName + "LoadFiles","scanner")

%% Create Data_Reader
d = Data_Reader(scanner);

%% Load the Scanning Data
d.GetScan();