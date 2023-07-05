n = "cutout1";

load(n);

sar.calData2 = permute(calData .* exp(1j*2*k*zBias_m),[4,1,2,5,3]);
sar.mult2monoData2 = permute(exp(-1j*k.*mult2monoData),[4,1,2,5,3]);
sar.sarData = reshape(sar.calData2 .* sar.mult2monoData2 .* sar.sarDataRaw,256,256,64);

load empty101 fmcw ant
sar.y_step_m = fmcw(2).lambda_m/4;

%% Create Image
im.nFFTx = 1024;
im.nFFTy = 512;
im.nFFTz = 512;

im.numX = 128;
im.numY = 128;
im.numZ = 128;
im.x_m = linspace(0.3/im.numX-0.15,0.15,im.numX)';
im.y_m = linspace(0.3/im.numY-0.15,0.15,im.numY);
im.z_m = reshape(linspace(0.1+0.4/im.numZ,0.5,im.numZ),1,1,[]);
im = uniform_SISO_2D_array_reconstructImage_3D(sar,fmcw(2),im,false);
im.dBMin = -10;
plotXYZdB(im.pxyz,im.x_m,im.y_m,im.z_m,[],im.dBMin,"Reconstructed Image "+n,12);
view(-30,17)

%% Save the file
save(".\data\"+n,"sar","ant","fmcw")