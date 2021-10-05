%% Test with empty set
load allEmpty

N = 256;
M = 200;
ra = linspace(0,fmcw.rangeMax_m,N);

s1 = squeeze(sar.sarDataRaw(:,1,1,1,:));
sf1 = fft(s1,N,2);

figure(1)
mesh(ra,1:M,abs(sf1),'FaceColor','interp','EdgeColor','none');
view(2)

s2 = squeeze(sar.sarDataRaw(:,1,1,2,:));
sf2 = fft(s2,N,2);

figure(2)
mesh(ra,1:M,abs(sf2),'FaceColor','interp','EdgeColor','none');
view(2)

%% Test with corner
load corner3

N = 256;
M = 200;
ra = linspace(0,fmcw.rangeMax_m,N);

s1 = squeeze(sar.sarDataRaw(:,1,1,1,:));
sf1 = fft(s1,N,2);

figure(1)
mesh(ra,1:M,abs(sf1),'FaceColor','interp','EdgeColor','none');
view(2)

s2 = squeeze(sar.sarDataRaw(:,1,1,2,:));
sf2 = fft(s2,N,2);

figure(2)
mesh(ra,1:M,abs(sf2),'FaceColor','interp','EdgeColor','none');
view(2)

%% Test with cutout
load half2

N = 256;
M = 200;
ra = linspace(0,fmcw.rangeMax_m,N);

s1 = squeeze(sar.sarDataRaw(:,1,1,1,:));
sf1 = fft(s1,N,2);

figure(1)
mesh(ra,1:M,abs(sf1),'FaceColor','interp','EdgeColor','none');
view(2)

s2 = squeeze(sar.sarDataRaw(:,1,1,2,:));
sf2 = fft(s2,N,2);

figure(2)
mesh(ra,1:M,abs(sf2),'FaceColor','interp','EdgeColor','none');
view(2)

%% Test with cutout
load cutout1

N = 256;
M = 256;
ra = linspace(0,fmcw.rangeMax_m,N);

s1 = squeeze(sar.sarDataRaw(:,1,1,1,:));
sf1 = fft(s1,N,2);

figure(1)
mesh(ra,1:M,abs(sf1),'FaceColor','interp','EdgeColor','none');
view(2)

s2 = squeeze(sar.sarDataRaw(:,1,1,2,:));
sf2 = fft(s2,N,2);

figure(2)
mesh(1:N,1:M,abs(sf2),'FaceColor','interp','EdgeColor','none');
view(2)