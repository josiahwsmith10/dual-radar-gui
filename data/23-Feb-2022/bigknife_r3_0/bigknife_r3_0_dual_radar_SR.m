%% Include Necessary Directories
addpath(genpath("../radar-imaging-toolbox-private"))
addpath(genpath("../dual-radar-fusion-SR"))
addpath(genpath("./"))

%% Load Data
[wav4,ant4,scanner4,target4,im4] = DualRadarLoadAll(["bigknife_r3_0","23-Feb-2022"],3,false,4,0,0.3);

%% Try Super-Resolution Algorithm
% target = DualRadarSR(target4,"./saved/fftnet6.tar",4096,"range","none");
t = tic;
target4 = DualRadarSR(target4,"./saved/fftnet105.tar",1024,"range","min-max","norm3",4);
toc(t);

%% Load Saved sarData
load bigknife_r3_0_sarData.mat

%% Set sarData (dual radar)
% target4.sarData = sarData3;
target4.sarData = sarData4_fftnet105;

%% Smooth sarData
target4.sarData = imgaussfilt3(real(target4.sarData),[2,2,0.01]) + 1j*imgaussfilt3(imag(target4.sarData),[2,2,0.01]);

%% Set Image Reconstruction Parameters and Create RadarImageReconstruction Object 3D
im4.nFFTx = 1024;
im4.nFFTy = 1024;
im4.nFFTz = 512;

im4.xMin_m = -0.1;
im4.xMax_m = 0.1;

im4.yMin_m = -0.2;
im4.yMax_m = 0.25;

im4.zMin_m = 0.3;
im4.zMax_m = 0.45;

im4.numX = 200;
im4.numY = 200;
im4.numZ = 100;

im4.isGPU = false;
im4.method = "Uniform 2-D SAR 3-D RMA";
% im4.method = "Uniform 2-D SAR 2-D FFT";

im4.isMult2Mono = true;
im4.zRef_m = 0.331;
im4.zSlice_m = im4.zRef_m;

% im4.im_method = "none";

% Reconstruct the Image
im4.Compute();

im4.dBMin = -10;
im4.dBTh = 0;
im4.fontSize = 25;
im4.Display();
title(im4.fig.h,"SR - bigknife\_r3\_0")

%% Display the image
im4.dBMin = -10;
im4.dBTh = 0;
im4.fontSize = 25;
im4.Display();
title(im4.fig.h,"SR - bigknife\_r3\_0")

%% Volume Viewer
im4.openInVolumeViewer()

%% Display the image
im4.isIso = true;
im4.dBMin = -15;
im4.fontSize = 25;
im4.Display();
title(im4.fig.h,"SR - bigknife_r3_0")

%% Save All (super-resolution)
RadarSaveAll(wav4,ant4,scanner4,target4,im4,"./bigknife_r3_0_SR.mat")

%% Load All (super-resolution)
[wav4,ant4,scanner4,target4,im4] = RadarLoadAll("./bigknife_r3_0_SR.mat",false);
