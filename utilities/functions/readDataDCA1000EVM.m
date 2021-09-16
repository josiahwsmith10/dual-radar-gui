%%% This script is used to read the binary file produced by the DCA1000
%%% and Mmwave Studio
%%% Command to run in Matlab GUI -
x = readDCA1000("corner1_1_Raw_0.bin");
% readDCA1000("adc_data_Raw_0.bin");


function [retVal] = readDCA1000(fileName)
%% global variables
% change based on sensor config
numADCSamples = 64; % number of ADC samples per chirp
numADCBits = 16; % number of ADC bits per sample
numRX = 4; % number of receivers
%% read file
% read .bin file
fid = fopen(fileName,'r');
adcData = fread(fid,'int16');
% if 12 or 14 bits ADC per sample compensate for sign extension
if numADCBits ~= 16
    l_max = 2^(numADCBits-1)-1;
    adcData(adcData > l_max) = adcData(adcData > l_max) - 2^numADCBits;
end
fclose(fid);
fileSize = size(adcData,1);

% for complex data
% filesize = 2 * numADCSamples*numChirps
numChirps = fileSize/2/numADCSamples/numRX;
LVDS = zeros(1,fileSize/2);
%combine real and imaginary part into complex data
%read in file: 2I is followed by 2Q
counter = 1;
for ii=1:4:fileSize-1
    LVDS(1,counter) = adcData(ii) + 1j*adcData(ii+2);
    LVDS(1,counter+1) = adcData(ii+1) + 1j*adcData(ii+3);
    counter = counter + 2;
end
% create column for each chirp
LVDS = reshape(LVDS, numADCSamples*numRX, numChirps);
%each row is data from one chirp
LVDS = LVDS.';

%organize data per RX
adcData = zeros(numRX,numChirps*numADCSamples);
for row = 1:numRX
    for ii = 1:numChirps
        disp((ii-1)*numADCSamples+1 + "," + ii*numADCSamples)
        disp(" ")
        adcData(row,(ii-1)*numADCSamples+1:ii*numADCSamples) = LVDS(ii,(row-1)*numADCSamples+1:row*numADCSamples);
    end
end
% return receiver data
retVal = adcData;
end