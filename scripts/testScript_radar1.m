%% Include Necessary Directories
addpath(genpath("../radar-imaging-toolbox-private"))
addpath(genpath("./"))

%% Load Data
[wav1,ant1,scanner1,target1,im1] = DualRadarLoadAll(["<fileName>","<date>"],1.5,false,4,0,0.3);

%% Set Image Reconstruction Parameters and Create RadarImageReconstruction Object 3D
im1.nFFTx = 512;
im1.nFFTy = 512;
im1.nFFTz = 512;

im1.xMin_m = -0.1;
im1.xMax_m = 0.1;

im1.yMin_m = -0.1;
im1.yMax_m = 0.1;

im1.zMin_m = 0.1;
im1.zMax_m = 0.5;

im1.numX = 200;
im1.numY = 200;
im1.numZ = 100;

im1.isGPU = false;
% im1.method = "Uniform 2-D SAR 3-D RMA";
im1.method = "Uniform 2-D SAR 2-D FFT";

im1.isMult2Mono = true;
im1.zRef_m = 0.3;
im1.zSlice_m = im1.zRef_m;

% im1.im_method = "none";

% Reconstruct the Image
im1.Compute();

im1.dBMin = -10;
im1.fontSize = 25;
im1.Display();
title(im1.fig.h,"Radar 1 - <fileName>")

%% Display the image
im1.isIso = true;
im1.dBMin = -15;
im1.fontSize = 25;
im1.Display();
title(im1.fig.h,"Radar 1 - <fileName>")