%% Include Necessary Directories
addpath(genpath("../radar-imaging-toolbox-private"))
addpath(genpath("./"))

%% Load Data
[wav3,ant3,scanner3,target3,im3] = DualRadarLoadAll(["<fileName>","<date>"],3,false,4,0,0.3);

%% Set Image Reconstruction Parameters and Create RadarImageReconstruction Object 3D
im3.nFFTx = 512;
im3.nFFTy = 512;
im3.nFFTz = 512;

im3.xMin_m = -0.1;
im3.xMax_m = 0.1;

im3.yMin_m = -0.1;
im3.yMax_m = 0.1;

im3.zMin_m = 0.1;
im3.zMax_m = 0.5;

im3.numX = 200;
im3.numY = 200;
im3.numZ = 100;

im3.isGPU = false;
% im3.method = "Uniform 2-D SAR 3-D RMA";
im3.method = "Uniform 2-D SAR 2-D FFT";

im3.isMult2Mono = true;
im3.zRef_m = 0.3;
im3.zSlice_m = im3.zRef_m;

% im3.im_method = "none";

% Reconstruct the Image
im3.Compute();

im3.dBMin = -10;
im3.fontSize = 25;
im3.Display();
title(im3.fig.h,"Dual Radar - <fileName>")

%% Display the image
im3.isIso = true;
im3.dBMin = -15;
im3.fontSize = 25;
im3.Display();
title(im3.fig.h,"Dual Radar - <fileName>")