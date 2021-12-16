classdef Data_Reader < handle
    % TODO: add different scanning types (cylindrical)
    
    properties
        numX = 256              % Number of x steps
        numY = 32               % Number of y steps
        numADC = 64             % Number of ADC samples
        numChirps = 4           % Number of chirps per frame
        
        nTx = 2                 % Number of transmit antennas
        nRx = 4                 % Number of receive antennas
        
        fmcw1                   % Struct to hold chirp parameters
        ant1                    % Struct to hold the antenna array properties
        fmcw2                   % Struct to hold chirp parameters
        ant2                    % Struct to hold the antenna array properties
        sar                     % Struct to hold the SAR scan properties
        
        savePath = ""           % Folder containing the raw .bin files
        scanName = ""           % Name of the scan
        
        % GUI related parameters
        textArea                % Text area in the GUI for showing statuses
    end
    
    methods
        function obj = Data_Reader(scanner)
            if nargin < 1
                return;
            end
            
            obj.textArea = scanner.textArea;
            
            obj.numX = scanner.numX;
            obj.numY = scanner.numY;
            obj.savePath = scanner.savePath;
            obj.scanName = scanner.fileName;
            obj.numADC = scanner.radar1.adcSamples;
            obj.nTx = scanner.radar1.nTx;
            obj.nRx = scanner.radar1.nRx;
            
            % Create fmcw property 
            obj.fmcw1 = scanner.radar1.fmcw;
            obj.fmcw2 = scanner.radar2.fmcw;
            
            % Create ant property
            obj.ant1 = scanner.radar1.ant;
            obj.ant2 = scanner.radar2.ant;
            
            % Create sar property
            obj.sar.numX = scanner.numX;
            obj.sar.numY = scanner.numY;
            obj.sar.x_step_m = scanner.xStep_m;
            obj.sar.y_step_m = scanner.yStep_m;
            obj.sar.isTwoDirectionScanning = true;
        end
        
        function err = GetScan(obj)
            % Reads in the entire scan data
            %
            % Outputs
            %   -1  :   Error in scan data
            %   1   :   SAR data in numX x numY x numADC
            
            obj.textArea.Value = "";
            pause(0.1);
            
            if obj.VerifyScan() == -1
                err = -1;
                return
            end
            
            % Create calibration data for radar 1
            if exist('./cal/cal1.mat','file')
                load('./cal/cal1','zBias_m','calData','mult2monoConst');
                k = reshape(obj.fmcw1.k,1,1,[]);
                obj.sar.calData1 = permute(calData .* exp(1j*2*k*zBias_m),[4,1,2,5,3]);
                obj.sar.mult2monoData1 = permute(exp(-1j*k.*mult2monoConst),[4,1,2,5,3]);
            end
            
            % Create calibration data for radar 2
            if exist('./cal/cal2.mat','file')
                load('./cal/cal2','zBias_m','calData','mult2monoConst');
                k = reshape(obj.fmcw2.k,1,1,[]);
                obj.sar.calData2 = permute(calData .* exp(1j*2*k*zBias_m),[4,1,2,5,3]);
                obj.sar.mult2monoData2 = permute(exp(-1j*k.*mult2monoConst),[4,1,2,5,3]);
            end
            
            % Create sarData array
            obj.sar.sarDataRaw = zeros(obj.numX,obj.nRx,obj.nTx,obj.numY,obj.numADC);
            
            % Load in each file and store in array
            for indFile = 1:obj.numY
                obj.textArea.Value = "Reading file #" + indFile;
                filePath = obj.savePath + "\" + obj.scanName + "_" + indFile + "_Raw_0.bin";
                tempData = obj.ReadFile(filePath);
                if ~mod(indFile,2)
                    tempData = flip(tempData,4);
                end
                obj.sar.sarDataRaw(:,:,:,indFile,:) = permute(tempData(:,:,1,:,:),[4,1,2,3,5]);
                obj.textArea.Value = "Loaded file #" + indFile;
                drawnow;
            end
            
            obj.textArea.Value = "Scan: " + obj.scanName + " loaded successfully!";
            
            fmcw(1) = obj.fmcw1;
            fmcw(2) = obj.fmcw2;
            ant(1) = obj.ant1;
            ant(2) = obj.ant2;
            sar = obj.sar; %#ok<PROP>
            
            save(cd + "\data\" + obj.scanName,"fmcw","ant","sar");
            
            obj.textArea.Value = "Saved file to: " + cd + "\data\" + obj.scanName;
            err = 1;
        end
        
        function data = ReadFile(obj,filePath)
            % Reads the data from a single file in the shape:
            % nRx x nTx x numChirps x numX x numADC
            
            data = zeros(obj.nRx,obj.nTx,obj.numChirps,obj.numX,obj.numADC);
            
            fid = fopen(filePath);
            
            adcDataSize = 2*obj.numADC;
            
            for indFrame = 1:obj.numX
                for indChirp = 1:obj.numChirps
                    for indTx = 1:obj.nTx
                        for indRx = 1:obj.nRx
                            % Read the data
                            dataChunk = fread(fid,adcDataSize,'uint16','l');
                            dataChunk = dataChunk - (dataChunk >= 2^15)*2^16;
                            adcOut = dataChunk(2:2:end) + 1j*dataChunk(1:2:end);
                            data(indRx,indTx,indChirp,indFrame,:) = adcOut;
                        end
                    end
                end
            end
            
            fclose(fid);
        end
        
        function err = VerifyFile(obj,filePath)
            % Verifies that the file has the expected size
            %
            % Outputs
            %   1   :   File does have expected size
            %   -1  :   File does not have expected size!
            
            expectedSize = 4*obj.nTx*obj.nRx*obj.numADC*obj.numChirps*obj.numX;
            if dir(filePath).bytes ~= expectedSize
                obj.textArea.Value = "ERROR: " + filePath + " does not have the correct size!";
                err = -1;
                return
            end
            err = 1;
        end
        
        function err = VerifyScan(obj)
            % Verifies that the scan was completed and every file has the
            % expected size
            %
            % Outputs
            %   1   :   Successfully verified the entire scan
            %   -1  :   Could not verify the scan
            
            % Check files
            for indFile = 1:obj.numY
                filePath = obj.savePath + "\" + obj.scanName + "_" + indFile + "_Raw_0.bin";
                if ~exist(filePath,'file')
                    % File does not exist
                    obj.textArea.Value = "ERROR: " + filePath + " does not exist";
                    err = -1;
                    return
                else
                    % File does exist
                    if obj.VerifyFile(filePath) == -1
                        err = -1;
                        return;
                    end
                end
            end
            
            obj.textArea.Value = "Verified scan files successfully!";
            err = 1;
        end
    end
end