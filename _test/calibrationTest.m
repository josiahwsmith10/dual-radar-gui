%% Create fmcw and ant
fmcw.fC = 79e9;
fmcw.c = 299792458;
fmcw.f0 = 77*1e9;
fmcw.K = 124.996*1e12;
fmcw.IdleTime_s = 10*1e-6;
fmcw.TXStartTime_s = 0*1e-6;
fmcw.ADCStartTime_s = 0*1e-6;
fmcw.ADCSamples = 64;
fmcw.fS = 2000*1e3;
fmcw.RampEndTime_s = 32*1e-6;
fmcw.lambda_m = fmcw.c/fmcw.fC;
fmcw.k = 2*pi/fmcw.c*(fmcw.f0 + fmcw.ADCStartTime_s*fmcw.K + fmcw.K*(0:fmcw.ADCSamples-1)/fmcw.fS);
fmcw.rangeMax_m = fmcw.fS*fmcw.c/(2*fmcw.K);

ant.nTx = 2;
ant.nRx = 4;
ant.nVx = 8;
ant.tx.xy_m = single([zeros(2,1),5e-3 + [1.5;3.5]*fmcw.lambda_m]);
ant.rx.xy_m = single([zeros(4,1),(0:0.5:1.5).'*fmcw.lambda_m]);
ant.vx.xy_m = [];
ant.vx.dxy_m = [];
for indTx = 1:ant.nTx
    ant.vx.xy_m = cat(1,ant.vx.xy_m,(ant.tx.xy_m(indTx,:) + ant.rx.xy_m)/2);
    ant.vx.dxy_m = cat(1,ant.vx.dxy_m,ant.tx.xy_m(indTx,:) - ant.rx.xy_m);
end
clear indTx
ant.tx.xyz_m = [ant.tx.xy_m,zeros(ant.nTx,1)];
ant.rx.xyz_m = [ant.rx.xy_m,zeros(ant.nRx,1)];
ant.tx.xyz_m = repmat(ant.tx.xyz_m,ant.nRx,1);
ant.tx.xyz_m = reshape(ant.tx.xyz_m,ant.nTx,ant.nRx,3);
ant.tx.xyz_m = permute(ant.tx.xyz_m,[2,1,3]);
ant.tx.xyz_m = reshape(ant.tx.xyz_m,ant.nVx,3);
ant.rx.xyz_m = repmat(ant.rx.xyz_m,ant.nTx,1);

ant.tx.xyz_m = single(reshape(ant.tx.xyz_m,ant.nVx,3));
ant.rx.xyz_m = single(reshape(ant.rx.xyz_m,ant.nVx,3));
ant.vx.xyz_m = single(reshape([ant.vx.xy_m,zeros(ant.nVx,1)],ant.nVx,3));

%% Read in the data
d = Data_Reader();
d.nRx = 4;
d.nTx = 2;
d.numChirps = 4;
d.numX = 2048;
d.numADC = 64;
calFilePath = cd + "/data/cal" + 2 + "/scan0_Raw_0.bin";
if d.VerifyFile(calFilePath) == 1
    data = d.ReadFile(calFilePath);
end
clear calFilePath

% Simulate the scenario
z0_mm = 300;

target.xyz_m = single([0,0,z0_mm*1e-3]);
Rt = reshape(pdist2(ant.tx.xyz_m,target.xyz_m),d.nRx,d.nTx);
Rr = reshape(pdist2(ant.rx.xyz_m,target.xyz_m),d.nRx,d.nTx);

k = reshape(fmcw.k,1,1,[]);
sarData = 1./(Rt.*Rr) .* exp(1j*(Rt+Rr).*k);
sarDataFFT = fft(sarData,2048,3)/2048;

% Get good phase thetaGood
[~,indZIdeal] = max(squeeze(mean(sarDataFFT,[1,2])));
rangeAxis_m = linspace(0,fmcw.rangeMax_m-fmcw.rangeMax_m/2048,2048).';
zIdeal_m = rangeAxis_m(indZIdeal);
cGood = sarDataFFT(:,:,indZIdeal);
thetaGood = angle(cGood);

% Get zBias_m offset between measured and ideal z
data = squeeze(mean(data,[3,4]));
dataFFT = fft(data,2048,3);
avgDataFFT = squeeze(mean(dataFFT,[1,2]));
[~,indZMeasured] = max(avgDataFFT .* (rangeAxis_m > z0_mm*0.75e-3 & rangeAxis_m < z0_mm*1.25e-3));
zMeasured_m = rangeAxis_m(indZMeasured);

zBias_m = zIdeal_m - zMeasured_m;

% Attempt range correction
dataFFT = fft(data .* exp(1j*2*k*zBias_m),2048,3);

% Get bad phase thetaBad
avgDataFFT = squeeze(mean(dataFFT,[1,2]));
[~,indZMeasured] = max(avgDataFFT .* (rangeAxis_m > z0_mm*0.75e-3 & rangeAxis_m < z0_mm*1.25e-3));
% debug: zMeasured_m = rangeAxis_m(indZMeasured);
cBad = dataFFT(:,:,indZMeasured);
thetaBad = angle(cBad);

% calData2 = exp(1j*(thetaGood-thetaBad));
calData = cGood./cBad;

% Create multitstatic-to-monostatic conversion data
mult2monoConst = reshape(ant.vx.dxy_m(:,2).^2 / (4*z0_mm*1e-3),d.nRx,d.nTx);

%% Create sar.calData2
sar.calData2 = permute(calData .* exp(1j*2*k*zBias_m),[4,1,2,5,3]);
sar.mult2monoData2 = permute(exp(-1j*k.*mult2monoConst),[4,1,2,5,3]);