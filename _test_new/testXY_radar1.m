%% Include Necessary Directories
addpath(genpath("../radar-imaging-toolbox-private"))
addpath(genpath("./"))

%% Load Data
[wav1,ant1,scanner1,target1,im1] = DualRadarLoadAll("cutout1_r3",1.5,false,15);

%% TEMP
sf = fft(permute(reshape(target1.sarData,256,256,64),[2,1,3]),[],3);
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
im1.nFFTx = 512;
im1.nFFTy = 512;
im1.nFFTz = 512;

im1.xMin_m = -0.1;
im1.xMax_m = 0.1;

im1.yMin_m = -0.1;
im1.yMax_m = 0.1;

im1.zMin_m = 0.085;
im1.zMax_m = 0.485;

im1.numX = 200;
im1.numY = 200;
im1.numZ = 100;

im1.isGPU = true;
% im1.method = "Uniform 2-D SAR 3-D RMA";
im1.method = "Uniform 2-D SAR 2-D FFT";

im1.isMult2Mono = true;
im1.zRef_m = 0.3;
im1.zSlice_m = im1.zRef_m;

% Reconstruct the Image
im1.Compute();

im1.dBMin = -10;
im1.fontSize = 25;
im1.Display();
title("Radar 1")

%% Display the image
im1.dBMin = -10;
im1.fontSize = 25;
im1.Display();
title("Radar 1")