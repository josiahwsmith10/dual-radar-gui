%% Load empty scene for 6843
load empty0sarImage

%% 1. Set File Name
%-------------------------------------------------------------------------%
filename = "empty0";
load(filename);

%% TEMP
sar.sarData = reshape(1 .* sar.sarDataRaw,sar.numX,ant.vx.numVx*sar.numY,fmcw.ADCSamples);
sar.y_step_m = fmcw.lambda_m/4;
sar.numY = ant.vx.numVx*sar.numY;

%% 2. Create fmcw, ant, and sar
%-------------------------------------------------------------------------%
sar.Z0_m = 0.36; % Middle of scene, used for multistatic-to-monostatic conversion

%% Phase Calibration
%-------------------------------------------------------------------------%
load calData3
sar.sarDataCal = reshape(sar.sarDataRaw,sar.numX,ant.vx.numVx,sar.numY,fmcw.ADCSamples);
% sarDataCal = numX x numVx x numY x ADCSamples

sar.sarDataCal = reshape(calData,1,ant.vx.numVx) .* sar.sarDataCal .* exp(1j*2*reshape(fmcw.k,1,1,1,[])*rangeBias_mm*1e-3);
% sarDataCal = numX x numVx x numY x ADCSamples
clear calData rangeBias_mm

%% Multistatic-to-Monostatic Conversion
%-------------------------------------------------------------------------%
sar.sarData = sar.sarDataCal .* exp(-1j* reshape(fmcw.k,1,1,1,[]) .* reshape(ant.vx.dxy(:,2),1,[]).^2 / (4*sar.Z0_m));
% sarData = numX x numVx x numY x ADCSamples
sar.sarData = reshape(sar.sarData,sar.numX,ant.vx.numVx*sar.numY,fmcw.ADCSamples);
% sarData = numX x numVx*numY x ADCSamples

%% Now sar has different parameters
sar.y_step_m = fmcw.lambda_m/4;
sar.numY = 256;
% sarData = numX x numY x ADCSamples

%% Set Imaging Parameters
%-------------------------------------------------------------------------%
im.nFFTx = 1024;
im.nFFTy = 1024;
im.nFFTz = 512;

im.numX = 128;
im.numY = 128;
im.numZ = 128;
im.x_m = linspace(0.5/im.numX-0.25,0.25,im.numX)';
im.y_m = linspace(0.5/im.numY-0.25,0.25,im.numY);
im.z_m = reshape(linspace(0.1+0.4/im.numZ,0.5,im.numZ),1,1,[]);

%% Reconstruct Image
%-------------------------------------------------------------------------%
im = uniform_SISO_2D_array_reconstructImage_3D(sar,fmcw,im,false); %,sarImage_empty);

%% Show the 3-D Image
im.dBMin = -10;
plotXYZdB(im.pxyz,im.x_m,im.y_m,im.z_m,[],im.dBMin,"Reconstructed Image " + filename,12);
view(-30,17)

%% Show the 2-D Image
indZ = 64;
figure(2)
plotXYdB(im.pxyz(:,:,indZ),im.x_m,im.y_m,-10,"x (m)","y (m)","Reconstructed Image at " + im.z_m(indZ)*1e3 + " mm",12)


%% Save the Scenario 
%-------------------------------------------------------------------------%
sar = rmfield(sar,{'sarDataRaw','sarDataCal'});
save("./savedData/" + filename,"sar","im","filename","-v7.3")




























%% Show the Image
%-------------------------------------------------------------------------%
im.dBMin = -10;
plotXYZdB(im.pxyz,im.x_m,im.y_m,im.z_m,[],im.dBMin,"Reconstructed Image",12);
view(-30,17)

%% Show the 2-D Image
indZ = 60;
figure
plotXYdB(im.pxyz(:,:,indZ),im.x_m,im.y_m,-10,"x (m)","y (m)","Reconstructed Image at " + im.z_m(indZ)*1e3 + " mm",12)

%% Save the Scenario 
%-------------------------------------------------------------------------%
sar = rmfield(sar,{'sarDataRaw','sarDataCal'});
save("./savedData/" + "rectilinearTest2","-v7.3")