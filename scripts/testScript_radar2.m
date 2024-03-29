%% Include Necessary Directories
addpath(genpath("../radar-imaging-toolbox-private"))
addpath(genpath("./"))

%% Load Data
[wav2,ant2,scanner2,target2,im2] = DualRadarLoadAll(["<fileName>","<date>"],2,false,4,0,0.3);

%% Set Image Reconstruction Parameters and Create RadarImageReconstruction Object 3D
im2.nFFTx = 512;
im2.nFFTy = 512;
im2.nFFTz = 512;

im2.xMin_m = -0.1;
im2.xMax_m = 0.1;

im2.yMin_m = -0.1;
im2.yMax_m = 0.1;

im2.zMin_m = 0.1;
im2.zMax_m = 0.5;

im2.numX = 200;
im2.numY = 200;
im2.numZ = 100;

im2.isGPU = false;
% im2.method = "Uniform 2-D SAR 3-D RMA";
im2.method = "Uniform 2-D SAR 2-D FFT";

im2.isMult2Mono = true;
im2.zRef_m = 0.3;
im2.zSlice_m = im2.zRef_m;

% im2.im_method = "none";

% Reconstruct the Image
im2.Compute();

im2.dBMin = -10;
im2.fontSize = 25;
im2.Display();
title(im2.fig.h,"Radar 2 - <fileName_title>")

%% Display the image
im2.isIso = true;
im2.dBMin = -15;
im2.fontSize = 25;
im2.Display();
title(im2.fig.h,"Radar 2 - <fileName_title>")