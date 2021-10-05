%% Load empty scene for 6843
load empty0sarImage

%% 1. Set File Name
%-------------------------------------------------------------------------%
filename = "empty101";
load(filename);

%% GOOD
% sar.sarData = reshape(sar.sarDataRaw,256,256,64);
% sar.sarData = reshape(sar.calData2 .* sar.sarDataRaw,256,256,64);
% sar.sarData = reshape(mult2monoData .* sar.sarDataRaw,256,256,64);
sar.sarData = reshape(sar.calData2 .* sar.mult2monoData2 .* sar.sarDataRaw,256,256,64);
sar.y_step_m = fmcw(2).lambda_m/4;

%% TEMP
sf = fft(sar.sarData,[],3);
figure
plot(abs(squeeze(sf(128,128,:))))

s = sf(:,:,9);
figure; 
plot(unwrap(angle(s(:,128)))); 

figure; 
plot(unwrap(angle(s(128,:))))

%% Set Imaging Parameters
%-------------------------------------------------------------------------%
im.nFFTx = 1024;
im.nFFTy = 512;
im.nFFTz = 512;

im.numX = 512;
im.numY = 512;
im.numZ = 128;
im.x_m = linspace(0.3/im.numX-0.15,0.15,im.numX)';
im.y_m = linspace(0.3/im.numY-0.15,0.15,im.numY);
im.z_m = reshape(linspace(0.1+0.4/im.numZ,0.5,im.numZ),1,1,[]);

%% Reconstruct Image
%-------------------------------------------------------------------------%
im = uniform_SISO_2D_array_reconstructImage_3D(sar,fmcw(2),im,false); %,sarImage_empty);

%% Show the 3-D Image
im.dBMin = -5;
plotXYZdB(im.pxyz,im.x_m,im.y_m,im.z_m,[],im.dBMin,"Reconstructed Image " + filename,12);
view(-30,17)

%% Show the 2-D Image
indZ = 75;
im.dBMin = -10;
figure
plotXYdB(im.pxyz(:,:,indZ),im.x_m,im.y_m,im.dBMin,"x (m)","y (m)","Reconstructed Image at " + im.z_m(indZ)*1e3 + " mm",12)


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