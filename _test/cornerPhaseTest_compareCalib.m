%% 1. Set File Name
%-------------------------------------------------------------------------%
filename = "corner20";
load(filename);

load ./cal/empty2

sar.x_m = (-(256-1)/2:(256-1)/2)*sar.x_step_m;
sar.y_m = sar.x_m;
[sar.X,sar.Y] = ndgrid(sar.x_m,sar.y_m);

%% Get different datatypes
sarRaw = reshape(sar.sarDataRaw,256,256,64);
sarRawME = reshape(sar.sarDataRaw - empty2.sarDataRaw,256,256,64);
sarCal = reshape(sar.calData2 .* sar.sarDataRaw,256,256,64);
sarCalME = reshape(sar.calData2 .* (sar.sarDataRaw - empty2.sarDataRaw),256,256,64);
sarMM = reshape(sar.calData2 .* conj(sar.mult2monoData2) .* sar.sarDataRaw,256,256,64);
sarMMME = reshape(sar.calData2 .* conj(sar.mult2monoData2) .* (sar.sarDataRaw - empty2.sarDataRaw),256,256,64);

%% sarRaw
sf = fft(sarRaw,[],3);
figure
plot(abs(squeeze(sf(128,128,:))))

s = sf(:,:,11);
figure;
plot(unwrap(angle(s(:,128))));
ylim([-80,40])

figure;
plot(unwrap(angle(s(128,:))))
ylim([-80,40])

%% sarRawME
sf = fft(sarRawME,[],3);
figure
plot(abs(squeeze(sf(128,128,:))))

s = sf(:,:,11);
figure;
plot(unwrap(angle(s(:,128))));
ylim([-80,40])

figure;
plot(unwrap(angle(s(128,:))))
ylim([-80,40])

%% sarCal
sf = fft(sarCal,[],3);
figure
plot(abs(squeeze(sf(128,128,:))))

s = sf(:,:,10);
figure;
plot(unwrap(angle(s(:,128))));
ylim([-80,40])

figure;
plot(unwrap(angle(s(128,:))))
ylim([-80,40])

%% sarCalME
sf = fft(sarCalME,[],3);
figure
plot(abs(squeeze(sf(128,128,:))))

s = sf(:,:,10);
figure;
plot(unwrap(angle(s(:,128))));
ylim([-80,40])

figure;
plot(unwrap(angle(s(128,:))))
ylim([-80,40])

%% sarMM
sf = fft(sarMM,[],3);
figure
plot(abs(squeeze(sf(128,128,:))))

s = sf(:,:,10);
figure;
plot(unwrap(angle(s(:,128))));
ylim([-80,40])

figure;
plot(unwrap(angle(s(128,:))))
ylim([-80,40])

%% sarMMME
sf = fft(sarMMME,[],3);
figure
plot(abs(squeeze(sf(128,128,:))))

s = sf(:,:,10);
figure;
plot(unwrap(angle(s(:,128))));
ylim([-80,40])

figure;
plot(unwrap(angle(s(128,:))))
ylim([-80,40])



%% Set Imaging Parameters
%-------------------------------------------------------------------------%
im.nFFTx = 1024;
im.nFFTy = 1024;
im.nFFTz = 1024;

im.numX = 1024;
im.numY = 1024;
im.numZ = 400;
im.x_m = linspace(0.3/im.numX-0.15,0.15,im.numX)';
im.y_m = linspace(0.3/im.numY-0.15,0.15,im.numY);
im.z_m = reshape(linspace(0.1+1.9/im.numZ,2,im.numZ),1,1,[]);

im.ra = linspace(0,fmcw(2).rangeMax_m-fmcw(2).rangeMax_m/512,512).';

%% Plot All on Massive Figure
sar2 = sar;
sar2.Z0_m = 315e-3;

figure


%%% sarRaw
sar2.sarData = sarRaw;
im = uniform_SISO_2D_array_reconstructImage_2D(sar2,fmcw(2),im,true);

%   Phase Profile X
subplot(4,6,1)
plotPhaseProfileX(sarRaw,sar.x_m,im);
title("Raw Phase Profile X")

%   PSF X
subplot(4,6,7)
plotPSFX(im)
title("Raw PSF X")

%   Phase Profile Y
subplot(4,6,13)
plotPhaseProfileY(sarRaw,sar.y_m,im);
title("Raw Phase Profile Y")

%   PSF Y
subplot(4,6,19)
plotPSFY(im)
title("Raw PSF Y")


%%% sarRawME
sar2.sarData = sarRawME;
im = uniform_SISO_2D_array_reconstructImage_2D(sar2,fmcw(2),im,true);

%   Phase Profile X
subplot(4,6,2)
plotPhaseProfileX(sarRawME,sar.x_m,im);
title("Raw - Empty Phase Profile X")

%   PSF X
subplot(4,6,8)
plotPSFX(im)
title("Raw - Empty PSF X")

%   Phase Profile Y
subplot(4,6,14)
plotPhaseProfileY(sarRawME,sar.y_m,im);
title("Raw - Empty Phase Profile Y")

%   PSF Y
subplot(4,6,20)
plotPSFY(im)
title("Raw - Empty PSF Y")


%%% sarCal
sar2.sarData = sarCal;
im = uniform_SISO_2D_array_reconstructImage_2D(sar2,fmcw(2),im,true);

%   Phase Profile X
subplot(4,6,3)
plotPhaseProfileX(sarCal,sar.x_m,im);
title("Calibrated Phase Profile X")

%   PSF X
subplot(4,6,9)
plotPSFX(im)
title("Calibrated PSF X")

%   Phase Profile Y
subplot(4,6,15)
plotPhaseProfileY(sarCal,sar.y_m,im);
title("Calibrated Phase Profile Y")

%   PSF Y
subplot(4,6,21)
plotPSFY(im)
title("Calibrated PSF Y")


%%% sarCalME
sar2.sarData = sarCalME;
im = uniform_SISO_2D_array_reconstructImage_2D(sar2,fmcw(2),im,true);

%   Phase Profile X
subplot(4,6,4)
plotPhaseProfileX(sarCalME,sar.x_m,im);
title("Calibrated - Empty Phase Profile X")

%   PSF X
subplot(4,6,10)
plotPSFX(im)
title("Calibrated - Empty PSF X")

%   Phase Profile Y
subplot(4,6,16)
plotPhaseProfileY(sarCalME,sar.y_m,im);
title("Calibrated - Empty Phase Profile Y")

%   PSF Y
subplot(4,6,22)
plotPSFY(im)
title("Calibrated - Empty PSF Y")


%%% sarMM
sar2.sarData = sarMM;
im = uniform_SISO_2D_array_reconstructImage_2D(sar2,fmcw(2),im,true);

%   Phase Profile X
subplot(4,6,5)
plotPhaseProfileX(sarMM,sar.x_m,im);
title("MIMO Compensation Phase Profile X")

%   PSF X
subplot(4,6,11)
plotPSFX(im)
title("MIMO Compensation PSF X")

%   Phase Profile Y
subplot(4,6,17)
plotPhaseProfileY(sarMM,sar.y_m,im);
title("MIMO Compensation Phase Profile Y")

%   PSF Y
subplot(4,6,23)
plotPSFY(im)
title("MIMO Compensation PSF Y")


%%% sarMMME
sar2.sarData = sarMMME;
im = uniform_SISO_2D_array_reconstructImage_2D(sar2,fmcw(2),im,true);

%   Phase Profile X
subplot(4,6,6)
plotPhaseProfileX(sarMMME,sar.x_m,im);
title("MIMO Compensation - Empty Phase Profile X")

%   PSF X
subplot(4,6,12)
plotPSFX(im)
title("MIMO Compensation - Empty PSF X")

%   Phase Profile Y
subplot(4,6,18)
plotPhaseProfileY(sarMMME,sar.y_m,im);
title("MIMO Compensation - Empty Phase Profile Y")

%   PSF Y
subplot(4,6,24)
plotPSFY(im)
title("MIMO Compensation - Empty PSF Y")







%% Reconstruct Image 2D
%-------------------------------------------------------------------------%
sar2 = sar;
sar2.sarData = sarRaw;
sar2.Z0_m = 300e-3;
im = uniform_SISO_2D_array_reconstructImage_2D(sar2,fmcw(2),im,true);
im.dBMin = -10;
figure
plotXYdB(im.pxy,im.x_m,im.y_m,im.dBMin,"x (m)","y (m)","Reconstructed Image at " + sar2.Z0_m*1e3 + " mm",12)
% plot(im.x_m,db(im.pxy(:,117)/max(im.pxy(:,117))))
% plot(im.y_m,db(im.pxy(116,:)/max(im.pxy(233,:))))
% plotPSFX(im)

% figure
% plotPSFY(im)

%%

function plotPSFX(im)
[~,ind] = max(im.pxy(:));
[~,indY] = ind2sub(size(im.pxy),ind);

psfx = im.pxy(:,indY);
plot(im.x_m,db(psfx/max(psfx)))
ylim([-100,0]);
xlim([im.x_m(1),im.x_m(end)])
end

function plotPSFY(im)
[~,ind] = max(im.pxy(:));
[indX,~] = ind2sub(size(im.pxy),ind);

psfy = im.pxy(:,indX);
plot(im.x_m,db(psfy/max(psfy)))
ylim([-100,0]);
xlim([im.y_m(1),im.y_m(end)])
end

function plotPhaseProfileX(sarData,x_m,im,N)
if nargin < 4
    N = 512;
end

ra = im.ra;

sf = fft(sarData,N,3);
[~,ind] = max(squeeze(sf(128,128,:)) .* (ra > 0.25 & ra < 0.35));

s = sf(:,:,ind);
plot(x_m,unwrap(angle(s(:,128))));
ylim([-120,40])
xlim([x_m(1),x_m(end)])
end

function plotPhaseProfileY(sarData,y_m,im,N)
if nargin < 4
    N = 512;
end

ra = im.ra;

sf = fft(sarData,N,3);
[~,ind] = max(squeeze(sf(128,128,:)) .* (ra > 0.25 & ra < 0.35));

s = sf(:,:,ind);
plot(y_m,unwrap(angle(s(128,:))))
ylim([-120,40])
xlim([y_m(1),y_m(end)])
end