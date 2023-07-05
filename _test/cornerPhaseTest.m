load corner20

%%
N = 256;

% sarData = reshape(sar.calData2 .* sar.sarDataRaw(:,[1,3,2,4],:,:,:),256,256,64);
sarData = reshape(1 .* sar.sarDataRaw(:,[4,3,2,1],[2,1],:,:),256,256,64);

s = squeeze(sarData(128,128,:));
sf = fft(s,N);

figure(1)
plot(abs(sf))

ra = linspace(0,fmcw(2).rangeMax_m,N);
[~,indMax] = max(abs(sf));
ra(indMax)

figure(2)
plot(ra,abs(sf))

%%
sarDataFFT = fft(sarData,N,3);
s2 = sarDataFFT(:,:,indMax);

%% Plot Phase Profiles
figure(3)
plot(unwrap(angle(s2(:,128))))

figure(4)
plot(unwrap(angle(s2(128,:))))


%% Plot 2D Phase Profile
figure(5)
mesh(unwrap(unwrap(angle(s2),[],1),[],2),'FaceColor','interp','EdgeColor','none')

%% Reconstruct Image
% sar.sarData = reshape(sar.calData2 .* sar.sarDataRaw(:,[1,3,2,4],[1,2],:,:),256,256,64);
sar.sarData = reshape(1 .* sar.sarDataRaw(:,[4,3,2,1],[1,2],:,:),256,256,64);
sar.y_step_m = fmcw(2).lambda_m/4;
sar.numY = 256;

%% Set Imaging Parameters
%-------------------------------------------------------------------------%
im.nFFTx = 512;
im.nFFTy = 512;
im.nFFTz = 512;

im.numX = 128;
im.numY = 128;
im.numZ = 128;
im.x_m = linspace(0.3/im.numX-0.15,0.15,im.numX)';
im.y_m = linspace(0.3/im.numY-0.15,0.15,im.numY);
im.z_m = reshape(linspace(0.1+0.4/im.numZ,0.5,im.numZ),1,1,[]);

%% Reconstruct Image
%-------------------------------------------------------------------------%
im = uniform_SISO_2D_array_reconstructImage_3D(sar,fmcw(2),im,false);

%% Show the 3-D Image
im.dBMin = -10;
plotXYZdB(im.pxyz,im.x_m,im.y_m,im.z_m,[],im.dBMin,"Reconstructed Image",12);
view(-30,17)

%% Show the 2-D Image
indZ = 128;
im.dBMin = -10;
figure(2)
plotXYdB(im.pxyz(:,:,indZ),im.x_m,im.y_m,im.dBMin,"x (m)","y (m)","Reconstructed Image at " + im.z_m(indZ)*1e3 + " mm",12)





%% Compare different combinations - baseline
sar.sarData = reshape(sar.sarDataRaw,256,256,64);
im = uniform_SISO_2D_array_reconstructImage_3D(sar,fmcw(2),im,false);
im.dBMin = -10;
plotXYZdB(im.pxyz,im.x_m,im.y_m,im.z_m,[],im.dBMin,"Baseline",12);
view(-30,17)

%% Flip Rx 2 and 3
sar.sarData = reshape(sar.sarDataRaw(:,[1,3,2,4],:,:,:),256,256,64);
im = uniform_SISO_2D_array_reconstructImage_3D(sar,fmcw(2),im,false);
im.dBMin = -10;
plotXYZdB(im.pxyz,im.x_m,im.y_m,im.z_m,[],im.dBMin,"Flip Rx 2 and 3",12);
view(-30,17)

%% Flip Tx 1 and 2 - totally off
sar.sarData = reshape(sar.sarDataRaw(:,[4,3,2,1],[2,1],:,:),256,256,64);
im = uniform_SISO_2D_array_reconstructImage_3D(sar,fmcw(2),im,false);
im.dBMin = -10;
plotXYZdB(im.pxyz,im.x_m,im.y_m,im.z_m,[],im.dBMin,"Flip Tx 1 and 2",12);
view(-30,17)

%% Reverse Rx
sar.sarData = reshape(sar.sarDataRaw(:,[4,3,2,1],:,:,:),256,256,64);
im = uniform_SISO_2D_array_reconstructImage_3D(sar,fmcw(2),im,false);
im.dBMin = -10;
plotXYZdB(im.pxyz,im.x_m,im.y_m,im.z_m,[],im.dBMin,"Reverse Rx",12);
view(-30,17)

%% Reverse Rx
sar.sarData = reshape(sar.sarDataRaw(:,[4,3,2,1],:,:,:),256,256,64);
im = uniform_SISO_2D_array_reconstructImage_3D(sar,fmcw(2),im,false);
im.dBMin = -10;
plotXYZdB(im.pxyz,im.x_m,im.y_m,im.z_m,[],im.dBMin,"Reverse Rx",12);
view(-30,17)



%% Try all combinations
p = perms(1:4);

for indP = 1:24
    sar.sarData = reshape(sar.sarDataRaw(:,p(indP,:),:,:,:),256,256,64);
    im = uniform_SISO_2D_array_reconstructImage_3D(sar,fmcw(2),im,false);
    im.dBMin = -10;
    plotXYZdB(im.pxyz,im.x_m,im.y_m,im.z_m,[],im.dBMin,p(indP,:),12);
    view(-30,17)
    drawnow
end




