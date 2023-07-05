%% Include Necessary Directories
addpath(genpath("../radar-imaging-toolbox-private"))
addpath(genpath("./"))

%% Load Data
[wav2,ant2,scanner2,target2,im2] = DualRadarLoadAll(["cutout2_r3_0","21-Feb-2022"],2,false,4,0,0.28);

%% TEMP
sf = fft(permute(target2.sarData,[2,1,3]),[],3);
figure(1)
plot(abs(squeeze(sf(128,128,:))))

s = sf(:,:,9);
figure(2)
plot(unwrap(angle(s(:,128))));
title("Phase X")

figure(3)
plot(unwrap(angle(s(128,:))))
title("Phase Y")

%% Set Image Reconstruction Parameters and Create RadarImageReconstruction Object 3D
im2.nFFTx = 512;
im2.nFFTy = 512;
im2.nFFTz = 512;

im2.xMin_m = -0.1;
im2.xMax_m = 0.1;

im2.yMin_m = -0.1;
im2.yMax_m = 0.1;

im2.zMin_m = 0.085;
im2.zMax_m = 0.485;

im2.numX = 200;
im2.numY = 200;
im2.numZ = 100;

im2.isGPU = false;
% im2.method = "Uniform 2-D SAR 3-D RMA";
im2.method = "Uniform 2-D SAR 2-D FFT";

im2.isMult2Mono = true;
im2.zRef_m = 0.337;
im2.zSlice_m = im2.zRef_m;

% im2.im_method = "none";

% Reconstruct the Image
im2.Compute();

im2.dBMin = -10;
im2.fontSize = 25;
im2.Display();
title(im2.fig.h,"Radar 2")

%% Display the image
im2.dBMin = -10;
im2.fontSize = 25;
im2.Display();
title(im2.fig.h,"Radar 2")