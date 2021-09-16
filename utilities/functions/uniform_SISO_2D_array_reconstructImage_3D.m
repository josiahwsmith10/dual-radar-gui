function im = uniform_SISO_2D_array_reconstructImage_3D(sar,fmcw,im,isGPU,sarImage_empty)
% sarData is of size (sar.Nx, sar.Ny, fmcw.Nk)
sarData = single(sar.sarData);

im.x_m = single(im.x_m);
im.y_m = single(im.y_m);
im.z_m = single(im.z_m);

%% Compute Wavenumbers
k = single(reshape(fmcw.k,1,1,[]));
L_x = im.nFFTx * sar.x_step_m;
dkX = 2*pi/L_x;
kX = make_kX(dkX,im.nFFTx).';

L_y = im.nFFTy * sar.y_step_m;
dkY = 2*pi/L_y;
kY = make_kX(dkY,im.nFFTy);

kZU = single(reshape(linspace(0,2*max(k),im.nFFTz),1,1,[]));
dkZU = kZU(2) - kZU(1);

%% Use gpuArray if Possible
if isGPU
    reset(gpuDevice);
    k = gpuArray(k);
    kX = gpuArray(kX);
    kY = gpuArray(kY);
    kZU = gpuArray(kZU);
    sarData = gpuArray(sarData);
end

kXU = repmat(kX,[1,im.nFFTy,im.nFFTz]);
kYU = repmat(kY,[im.nFFTx,1,im.nFFTz]);
kU = single(1/2 * sqrt(kX.^2 + kY.^2 + kZU.^2));

%% Zero-Pad Data: s(x,y,k)
sarDataPadded = sarData;
sarDataPadded = cat(1,zeros(floor((im.nFFTx-size(sarData,1))/2),size(sarDataPadded,2),size(sarDataPadded,3)),sarDataPadded);
sarDataPadded = cat(2,zeros(size(sarDataPadded,1),floor((im.nFFTy-size(sarData,2))/2),size(sarDataPadded,3)),sarDataPadded);
clear sarData

%% Compute FFT across Y & X Dimensions: S(kX,kY,k)
sarDataFFT = fftshift(fftshift(fft(fft(conj(sarDataPadded),im.nFFTx,1),im.nFFTy,2),1),2)/im.nFFTx/im.nFFTy;
clear sarDataPadded

%% Stolt Interpolation: S(kX,kY,k)
sarImageFFT = interpn(kX(:),kY(:),k(:), sarDataFFT ,kXU,kYU,kU,'linear',0);
clear sarDataFFT k kU kX kXU kY kYU kZU

if isGPU
    sarImageFFT = gather(sarImageFFT);
    reset(gpuDevice);
    sarImageFFT = gpuArray(sarImageFFT);
end

%% Recover Image by IFT: p(x,y,z)
% sarImage_uncal = single(abs(ifftn(sarImageFFT)));
sarImage_uncal = single(ifftn(sarImageFFT));
clear sarImageFFT

%% Calibrate with the empty space image for FFT Size 1024 x 1024 x 512
if nargin == 5 && im.nFFTx == 1024 && im.nFFTy == 1024 && im.nFFTz == 512
    sarImage = abs(sarImage_uncal - sarImage_empty);
else
    sarImage = abs(sarImage_uncal);
end
clear sarImage_uncal

%% Declare Spatial Vectors
x_m = make_x(sar.x_step_m,im.nFFTx);
y_m = make_x(sar.y_step_m,im.nFFTy);
z_m = single(2*pi / (dkZU * im.nFFTz) * (1:im.nFFTz));

%% Resize Image - take only region of interest
if max(im.x_m) > max(x_m)
    warning("WARNING: im.nFFTx is too small to see the image! Changing im.x_m")
    im.x_m = x_m;
end
if max(im.y_m) > max(y_m)
    warning("WARNING: im.nFFTy is too small to see the image! Changing im.y_m")
    im.y_m = y_m;
end
if max(im.z_m) > max(z_m)
    warning("WARNING: im.nFFTz is too small to see the image! Changing im.z_m")
    im.z_m = z_m;
end

[X,Y,Z] = ndgrid(im.x_m(:),im.y_m(:),im.z_m(:));
im.pxyz = single(gather(interpn(x_m(:),y_m(:),z_m(:),sarImage,X,Y,Z,'nearest',0)));
if isGPU
    reset(gpuDevice);
end
end

function x = make_x(xStep_m,nFFTx)
x = xStep_m * (-(nFFTx-1)/2 : (nFFTx-1)/2);
x = single(x);
end

function kX = make_kX(dkX,nFFTx)
if mod(nFFTx,2)==0
    kX = dkX * ( -nFFTx/2 : nFFTx/2-1 );
else
    kX = dkX * ( -(nFFTx-1)/2 : (nFFTx-1)/2 );
end
kX = single(kX);
end