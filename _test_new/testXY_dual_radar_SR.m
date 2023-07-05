%% Include Necessary Directories
addpath(genpath("../radar-imaging-toolbox-private"))
addpath(genpath("../dual-radar-fusion-SR"))
addpath(genpath("./"))

%% Load Data
[wav4,ant4,scanner4,target4,im4] = DualRadarLoadAll(["spheres512_r3_4","21-Feb-2022"],3,false,4,0.5,0.34);

%% Try Super-Resolution Algorithm
target4 = DualRadarSR(target4,"./saved/fftnet5.tar",4096,"range");

%% Set Image Reconstruction Parameters and Create RadarImageReconstruction Object 3D
im4.nFFTx = 512;
im4.nFFTy = 512;
im4.nFFTz = 512;

im4.xMin_m = -0.1;
im4.xMax_m = 0.1;

im4.yMin_m = -0.1;
im4.yMax_m = 0.1;

im4.zMin_m = 0.2;
im4.zMax_m = 0.4;

im4.numX = 200;
im4.numY = 200;
im4.numZ = 200;

im4.isGPU = true;
im4.method = "Uniform 2-D SAR 3-D RMA";
% im4.method = "Uniform 2-D SAR 2-D FFT";

im4.isMult2Mono = true;
im4.zRef_m = 0.3015;
im4.zSlice_m = im4.zRef_m;

% Reconstruct the Image
im4.Compute();

im4.dBMin = -10;
im4.fontSize = 25;
im4.Display();
title(im4.fig.h,"Dual Radar SR")

%% Display the image
im4.dBMin = -10;
im4.fontSize = 25;
im4.Display();
title(im4.fig.h,"Dual Radar")