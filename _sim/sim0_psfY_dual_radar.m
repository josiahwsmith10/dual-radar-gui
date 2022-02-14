%% Include Necessary Directories
addpath(genpath("../radar-imaging-toolbox-private"))
addpath(genpath("./"))

%% Create the Objects
wav = TIRadarWaveformParameters();
ant = RadarAntennaArray(wav);
scanner = RadarScanner(ant);
target = RadarTarget(wav,ant,scanner);
im = RadarImageReconstruction(wav,ant,scanner,target);

%% Set Waveform Parameters
wav.f0 = 77e9;
wav.K = 124.998e12;
wav.ADCStartTime_s = 0e-6;
wav.Nk = 336;
wav.fS = 2000e3;
wav.RampEndTime_s = 168e-6;
wav.fC = 79e9;
wav.B = 4e9;

wav.Compute();

%% Set Antenna Array Properties
ant.isEPC = true;
ant.z0_m = 0;
% Large MIMO Array
ant.tableTx = [
    0   0   1.5   5   1
    0   0   3.5   5   1];
ant.tableRx = [
    0   0   0   0   1
    0   0   0.5 0   1
    0   0   1   0   1
    0   0   1.5 0   1];
ant.Compute();

% Display the Antenna Array
ant.Display();

%% Set Scanner Parameters
scanner.method = "Linear";
scanner.yStep_m = wav.lambda_m*2;
scanner.numY = 32;

scanner.Compute();

% Display the Synthetic Array
scanner.Display();

%% Set Target Parameters
target.isAmplitudeFactor = false;

% Two points
target.tableTarget = [
    0   0       0.3    1];

% Which to use
target.isTable = true;
target.isPNG = false;
target.isSTL = false;
target.isRandomPoints = false;

target.Get();

% Display the target
target.Display();

%% Compute the Beat Signal
target.isGPU = true;
target.Compute();

sarDataDR = target.sarData;

%% Set Image Reconstruction Parameters and Create RadarImageReconstruction Object
target.sarData = zeros(size(sarDataDR),"single");
% target.sarData(:,1:64) = sarDataDR(:,1:64);                       % Radar 1 only
% target.sarData(:,273:end) = sarDataDR(:,273:end);                 % Radar 2 only
target.sarData(:,[1:64,273:end]) = sarDataDR(:,[1:64,273:end]);   % Dual radar
% target.sarData = sarDataDR;                                       % Full band

im.nFFTy = 512;
im.nFFTz = 512;

im.yMin_m = -0.1;
im.yMax_m = 0.1;

im.zMin_m = 0.2;
im.zMax_m = 0.4;

im.numY = 200;
im.numZ = 200;

im.isGPU = true;
im.zSlice_m = 0.3; % Use if reconstructing a 2-D image
im.method = "Uniform 1-D SAR 2-D RMA";

im.isMult2Mono = true;
im.zRef_m = 0.3;

% Reconstruct the Image
im.Compute();

% Display the Image
im.dBMin = -15;
im.fontSize = 25;
im.Display();
title("Dual Radar")

%% Display the Image with Different Parameters
im.dBMin = -10;
im.fontSize = 25;
im.Display();
title("")

%% Radar 1
target.sarData = zeros(size(sarDataDR),"single");
target.sarData(:,1:64) = sarDataDR(:,1:64);                       % Radar 1 only
% Reconstruct the Image
im.Compute();

% Display the Image
im.Display();
title("Radar 1")

%% Radar 2
target.sarData = zeros(size(sarDataDR),"single");
target.sarData(:,273:end) = sarDataDR(:,273:end);                 % Radar 2 only
% Reconstruct the Image
im.Compute();

% Display the Image
im.Display();
title("Radar 2")

%% Dual Radar
target.sarData = zeros(size(sarDataDR),"single");
target.sarData(:,[1:64,273:end]) = sarDataDR(:,[1:64,273:end]);   % Dual radar
% Reconstruct the Image
im.Compute();

% Display the Image
im.Display();
title("Dual Radar")

%% Full Band
target.sarData = zeros(size(sarDataDR),"single");
target.sarData = sarDataDR;                                       % Full band
% Reconstruct the Image
im.Compute();

% Display the Image
im.Display();
title("Full Band")




%% Save All
RadarSaveAll(wav,ant,scanner,target,im,"./results/sim1_UTD_RMA.mat")

%% Load All
[wav,ant,scanner,target,im] = RadarLoadAll("./results/sim1_UTD_RMA.mat");