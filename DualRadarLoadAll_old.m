% Loads all simulation objects from a file saved by dual-radar-gui
%   loadPathFull    -   Path to .mat file saved by dual-radar gui
%   radarSelect     -   Selection for radar data format. 
%                           Options:
%                           1   :   radar 1 (no interpolation)
%                           1.5 :   radar 1 (with interpolation)
%                           2   :   radar 2 (no interpolation)
%                           3   :   dual-radar (with interpolation)
%
% Copyright (C) 2021 Josiah W. Smith
%
% This program is free software: you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the
% Free Software Foundation, either version 3 of the License, or (at your
% option) any later version.
%
% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
% Public License for more details.

function [wav,ant,scanner,target,im] = DualRadarLoadAll_old(loadPathFull,radarSelect,isDisplay,yBias_mm)
if nargin < 1
    loadPathFull = [];
end

if nargin < 2
    radarSelect = 3;
end

if nargin < 3
    isDisplay = true;
end

if nargin < 4
    yBias_mm = 0;
end

if radarSelect < 1 || radarSelect > 3
    warning("radarSelect must be between 1 and 3")
    wav = [];
    ant = [];
    scanner = [];
    target = [];
    im = [];
    return;
end

if ~exist(loadPathFull,'file')
    [filename,pathname] = uiputfile("./*.mat","Select Desired File Location + Name for Save");

    if filename == 0
        warning("All scenario file not saved!");
        return;
    else
        loadPathFull = string(pathname) + string(filename);
    end
end

load(loadPathFull,"ant","fmcw","sar")

% Make necessary changes
fmcw(1).Nk = fmcw(1).ADCSamples;
fmcw(2).Nk = fmcw(2).ADCSamples;

ant(1).tx.numTx = ant(1).nTx;
ant(1).rx.numRx = ant(1).nRx;
ant(1).vx.numVx = ant(1).nVx;
ant(2).tx.numTx = ant(2).nTx;
ant(2).rx.numRx = ant(2).nRx;
ant(2).vx.numVx = ant(2).nVx;
ant(1).tx.isDualRadar = true;
ant(2).tx.isDualRadar = true;
ant_dr = ant;

sarData = cell(1,2);
sarData{1} = permute(sar.calData1 .* (sar.sarDataRaw1 - sar.sarDataEmpty1),[2,3,4,1,5]);
sarData{2} = permute(sar.calData2 .* (sar.sarDataRaw2 - sar.sarDataEmpty2),[2,3,4,1,5]);

if radarSelect == 1 || radarSelect == 2
    % Give the data from either radar 1 or 2 without interpolation (will
    % result in non-uniform data for at least one of the radars due to the
    % different antenna spacing)

    % Get wav fields from fmcw struct
    wav = TIRadarWaveformParameters();
    wav = getFields(wav,fmcw(radarSelect),["app","isApp","ADCSamples"]);
    wav.Compute();

    % Get wav fields from ant_dr struct
    ant = RadarAntennaArray(wav);
    ant = getFields(ant,ant_dr(radarSelect),["app","fig","wav","isApp","nTx","nRx","nVx"]);
    ant.tableTx = [
        0   0   1.5   5   1
        0   0   3.5   5   1];
    ant.tableRx = [
        0   0   0   0   1
        0   0   0.5 0   1
        0   0   1   0   1
        0   0   1.5 0   1];
    ant.Compute();
    if isDisplay
        ant.Display();
    end

    % Create scanner
    scanner = RadarScanner(ant);
    scanner.method = "Rectilinear";
    scanner.xStep_m = sar.x_step_m;
    scanner.numX = sar.numX;
    scanner.yStep_m = sar.y_step_m;
    scanner.numY = sar.numY;

    scanner.Compute();
    if isDisplay
        scanner.Display();
    end

    % Create target
    target = RadarTarget(wav,ant,scanner);
    target.sarData = sarData{radarSelect};
    target.isAmplitudeFactor = true;
    target.isGPU = true;

    % Create im
    im = RadarImageReconstruction(wav,ant,scanner,target);
elseif radarSelect == 1.5
    % Give the interpolated data from radar 1 Create objects
    wav = [TIRadarWaveformParameters(),TIRadarWaveformParameters()];
    ant = [RadarAntennaArray(wav(1)),RadarAntennaArray(wav(2))];
    scanner = [RadarScanner(ant(1)),RadarScanner(ant(2))];

    sarDataXY = cell(1,3);
    for radarSelect = 1:2
        wav(radarSelect) = getFields(wav(radarSelect),fmcw(radarSelect),["app","isApp","ADCSamples"]);
        wav(radarSelect).Compute();

        % Get wav fields from ant_dr struct
        ant(radarSelect) = RadarAntennaArray(wav(radarSelect));
        ant(radarSelect) = getFields(ant(radarSelect),ant_dr(radarSelect),["app","fig","wav","isApp","nTx","nRx","nVx"]);
        ant(radarSelect).tableTx = [
            0   0   1.5   5   1
            0   0   3.5   5   1];
        ant(radarSelect).tableRx = [
            0   0   0   0   1
            0   0   0.5 0   1
            0   0   1   0   1
            0   0   1.5 0   1];
        ant(radarSelect).Compute();

        % Create scanner
        scanner(radarSelect) = RadarScanner(ant(radarSelect));
        scanner(radarSelect).method = "Rectilinear";
        scanner(radarSelect).xStep_m = sar.x_step_m;
        scanner(radarSelect).numX = sar.numX;
        scanner(radarSelect).yStep_m = sar.y_step_m;
        scanner(radarSelect).numY = sar.numY;

        scanner(radarSelect).Compute();

        sarDataXY{radarSelect} = permute(reshape(sarData{radarSelect},ant(radarSelect).vx.numVx*scanner(radarSelect).numY,scanner(radarSelect).numX,wav(radarSelect).Nk),[2,1,3]);
    end

    % Interpolate data to new grid
    sarDataXY{3} = zeros(size(sarDataXY{1}),"single");
    x1_m = scanner(1).x_m;
    y1_m = repmat(reshape(scanner(1).y_m,1,[]),8,1) + ant(1).vx.xyz_m(:,2);

    % Sort so the samples are always ascending
    [y1_m,ind_y1] = sort(y1_m(:));
    sarDataXY{3} = sarDataXY{3}(:,ind_y1,:);

    x2_m = scanner(2).x_m;
    y2_m = repmat(reshape(scanner(2).y_m,1,[]),8,1) + ant(2).vx.xyz_m(:,2) + yBias_mm*1e-3;

    [X2_m,Y2_m] = ndgrid(x2_m(:),y2_m(:));

    for indK = 1:wav(1).Nk
        sarDataXY{3}(:,:,indK) = interpn(x1_m(:),y1_m(:),sarDataXY{1}(:,:,indK),X2_m,Y2_m,"spline",0);
    end

    % Start with f0 = 60 GHz, but 336 ADC samples
    wav = wav(1);

    % Start with 77 GHz antenna spacing and scanner
    ant = ant(2);
    ant.wav = wav;
    scanner = scanner(2);
    scanner.ant = ant;
    if isDisplay
        ant.Display();
        scanner.Display();
    end

    % Create target
    target = RadarTarget(wav,ant,scanner);
    target.sarData = reshape(permute(sarDataXY{3},[2,1,3]),[scanner.sarSize,fmcw(1).ADCSamples]);
    target.isAmplitudeFactor = true;
    target.isGPU = true;

    % Create im
    im = RadarImageReconstruction(wav,ant,scanner,target);
elseif radarSelect == 3
    % Give the data from the radars with interpolation

    % Create objects
    wav = [TIRadarWaveformParameters(),TIRadarWaveformParameters()];
    ant = [RadarAntennaArray(wav(1)),RadarAntennaArray(wav(2))];
    scanner = [RadarScanner(ant(1)),RadarScanner(ant(2))];

    sarDataXY = cell(1,3);
    for radarSelect = 1:2
        wav(radarSelect) = getFields(wav(radarSelect),fmcw(radarSelect),["app","isApp","ADCSamples"]);
        wav(radarSelect).Compute();

        % Get wav fields from ant_dr struct
        ant(radarSelect) = RadarAntennaArray(wav(radarSelect));
        ant(radarSelect) = getFields(ant(radarSelect),ant_dr(radarSelect),["app","fig","wav","isApp","nTx","nRx","nVx"]);
        ant(radarSelect).tableTx = [
            0   0   1.5   5   1
            0   0   3.5   5   1];
        ant(radarSelect).tableRx = [
            0   0   0   0   1
            0   0   0.5 0   1
            0   0   1   0   1
            0   0   1.5 0   1];
        ant(radarSelect).Compute();

        % Create scanner
        scanner(radarSelect) = RadarScanner(ant(radarSelect));
        scanner(radarSelect).method = "Rectilinear";
        scanner(radarSelect).xStep_m = sar.x_step_m;
        scanner(radarSelect).numX = sar.numX;
        scanner(radarSelect).yStep_m = sar.y_step_m;
        scanner(radarSelect).numY = sar.numY;

        scanner(radarSelect).Compute();

        sarDataXY{radarSelect} = permute(reshape(sarData{radarSelect},ant(radarSelect).vx.numVx*scanner(radarSelect).numY,scanner(radarSelect).numX,wav(radarSelect).Nk),[2,1,3]);
    end

    % Interpolate data to new grid
    sarDataXY{3} = zeros(size(sarDataXY{1}),"single");
    x1_m = scanner(1).x_m;
    y1_m = repmat(reshape(scanner(1).y_m,1,[]),8,1) + ant(1).vx.xyz_m(:,2);

    % Sort so the samples are always ascending
    [y1_m,ind_y1] = sort(y1_m(:));
    sarDataXY{3} = sarDataXY{3}(:,ind_y1,:);

    x2_m = scanner(2).x_m;
    y2_m = repmat(reshape(scanner(2).y_m,1,[]),8,1) + ant(2).vx.xyz_m(:,2) + yBias_mm*1e-3;

    [X2_m,Y2_m] = ndgrid(x2_m(:),y2_m(:));

    for indK = 1:wav(1).Nk
        sarDataXY{3}(:,:,indK) = interpn(x1_m(:),y1_m(:),sarDataXY{1}(:,:,indK),X2_m,Y2_m,"linear",0);
    end

    % Start with f0 = 60 GHz, but 336 ADC samples
    wav = wav(1);
    wav.Nk = 336;
    wav.RampEndTime_s = 168e-6;
    wav.Compute();

    % Start with 77 GHz antenna spacing and scanner
    ant = ant(2);
    ant.wav = wav;
    scanner = scanner(2);
    scanner.ant = ant;
    if isDisplay
        ant.Display();
        scanner.Display();
    end

    % Create target
    target = RadarTarget(wav,ant,scanner);
    target.sarData = zeros([scanner.sarSize,wav.Nk],"single");
    target.sarData(:,:,:,:,1:fmcw(1).ADCSamples) = reshape(permute(sarDataXY{3},[2,1,3]),[scanner.sarSize,fmcw(1).ADCSamples]);
    target.sarData(:,:,:,:,(end-fmcw(2).ADCSamples+1):end) = reshape(permute(sarDataXY{2},[2,1,3]),[scanner.sarSize,fmcw(2).ADCSamples]);
    target.isAmplitudeFactor = true;
    target.isGPU = true;

    % Create im
    im = RadarImageReconstruction(wav,ant,scanner,target);
end
end