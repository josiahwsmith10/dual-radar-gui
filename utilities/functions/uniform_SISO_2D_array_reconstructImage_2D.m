function im = uniform_SISO_2D_array_reconstructImage_2D(sar,fmcw,im,isGPU)
% sarData is of size (sar.Nx, sar.Ny, fmcw.Nk)
sarData = single(sar.sarData);

im.x_m = single(im.x_m);
im.y_m = single(im.y_m);

%% Compute Wavenumbers
k = single(reshape(fmcw.k,1,1,[]));
L_x = im.nFFTx * sar.x_step_m;
dkX = 2*pi/L_x;
kX = make_kX(dkX,im.nFFTx).';

L_y = im.nFFTy * sar.y_step_m;
dkY = 2*pi/L_y;
kY = make_kX(dkY,im.nFFTy);

kZ = single(sqrt((4 * k.^2 - kX.^2 - kY.^2) .* (4 * k.^2 > kX.^2 + kY.^2)));

%% Declare Spatial Vectors
x_m = make_x(sar.x_step_m,im.nFFTx);
y_m = make_x(sar.y_step_m,im.nFFTy);

%% Resize Image - take only region of interest
if max(im.x_m) > max(x_m)
    warning("WARNING: im.nFFTx is too small to see the image! Changing im.x_m")
    im.x_m = x_m;
end
if max(im.y_m) > max(y_m)
    warning("WARNING: im.nFFTy is too small to see the image! Changing im.z_m")
    im.y_m = y_m;
end

%% Use gpuArray if Possible
if isGPU
    kZ = gpuArray(kZ);
    sarData = gpuArray(sarData);
end

%% Zero-Pad Data: s(x,y,k)
sarDataPadded = sarData;
sarDataPadded = padarray(sarDataPadded,[floor((im.nFFTx-size(sarData,1))/2) 0],0,'pre');
sarDataPadded = padarray(sarDataPadded,[0 floor((im.nFFTy-size(sarData,2))/2)],0,'pre');
clear sarData

%% Compute FFT across Y & X Dimensions: S(kX,kY,k)
sarDataFFT = fftshift(fftshift(fft(fft(sarDataPadded,im.nFFTx,1),im.nFFTy,2),1),2)/im.nFFTx/im.nFFTy;
clear sarDataPadded

%% Focusing Filter 
focusingFilter = exp(-1j*kZ*sar.Z0_m);
focusingFilter(4 * k.^2 < kX.^2 + kY.^2) = 0;
sarImageFFT = sum(sarDataFFT .* focusingFilter,3);

%% Recover Image by IFT: p(x,y,z)
sarImage = single(abs(ifftn(sarImageFFT)));
clear sarImageFFT

[X,Y] = ndgrid(im.x_m(:),im.y_m(:));
im.pxy = single(gather(interpn(x_m(:),y_m(:),sarImage,X,Y,'nearest',0)));
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