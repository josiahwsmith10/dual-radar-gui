classdef Data_Reader < handle
    % TODO: add different scanning types (cylindrical)

    properties
        numX = 256              % Number of x steps
        numY = 32               % Number of y steps
        numADC = 64             % Number of ADC samples
        numChirps = 4           % Number of chirps per frame

        nTx = 2                 % Number of transmit antennas
        nRx = 4                 % Number of receive antennas

        fmcw1                   % Struct to hold chirp parameters for radar 1
        ant1                    % Struct to hold the antenna array properties for radar 1
        radar1                  % Struct to hold the properties for radar 1

        fmcw2                   % Struct to hold chirp parameters for radar 2
        ant2                    % Struct to hold the antenna array properties for radar 2
        radar2                  % Struct to hold the properties for radar 2

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

            % Create fmcw structs
            obj.fmcw1 = scanner.radar1.fmcw;
            obj.fmcw2 = scanner.radar2.fmcw;

            % Create ant structs
            obj.ant1 = scanner.radar1.ant;
            obj.ant2 = scanner.radar2.ant;

            % Create radar structs
            obj.radar1.serialNumber = scanner.radar1.serialNumber;
            obj.radar1.num = scanner.radar1.num;
            obj.radar2.serialNumber = scanner.radar2.serialNumber;
            obj.radar2.num = scanner.radar2.num;

            % Create sar struct
            obj.sar.numX = scanner.numX;
            obj.sar.numY = scanner.numY;
            obj.sar.x_step_m = scanner.xStep_m;
            obj.sar.y_step_m = scanner.yStep_m;
            obj.sar.isTwoDirectionScanning = scanner.isTwoDirection;
            obj.sar.radarSelect = scanner.radarSelect;
        end

        function err = GetScan(obj)
            % Reads in the entire scan data
            %
            % Outputs
            %   -1  :   Error in scan data
            %   1   :   SAR data in numX x numY x numADC

            obj.textArea.Value = "";
            pause(0.1);

            % Verify Scan
            if obj.VerifyScan() == -1
                err = -1;
                return
            end

            % Load Data
            if obj.LoadData() == -1
                err = -1;
                return;
            end

            % Create Calibration Data
            if obj.sar.radarSelect == 1 || obj.sar.radarSelect == 3
                obj.CreateCalibrationData(obj.radar1);
            end
            if obj.sar.radarSelect == 2 || obj.sar.radarSelect == 3
                obj.CreateCalibrationData(obj.radar2);
            end

            % Save data
            fmcw(1) = obj.fmcw1;
            fmcw(2) = obj.fmcw2;
            ant(1) = obj.ant1;
            ant(2) = obj.ant2;
            sar = obj.sar; %#ok<PROP>

            save(cd + "\data\" + date + "\" + obj.scanName,"fmcw","ant","sar","-v7.3");

            obj.textArea.Value = "Saved file to: " + cd + "\data\" + date + "\" + obj.scanName;
            err = 1;
        end

        function err = LoadData(obj)
            % Reads in the entire scan data for all radars in use
            %
            % Outputs
            %   -1  :   Error in scan data
            %   1   :   SAR data in numX x numY x numADC

            if obj.sar.radarSelect == 1
                obj.sar.sarDataRaw1 = obj.ReadSARScan();
                if isempty(obj.sar.sarDataRaw1)
                    err = -1;
                    return;
                end
            elseif obj.sar.radarSelect == 2
                obj.sar.sarDataRaw2 = obj.ReadSARScan();
                if isempty(obj.sar.sarDataRaw2)
                    err = -1;
                    return;
                end
            elseif obj.sar.radarSelect == 3
                obj.sar.sarDataRaw1 = obj.ReadSARScan(obj.savePath + "\radar1");
                if isempty(obj.sar.sarDataRaw1)
                    err = -1;
                    return;
                end
                obj.sar.sarDataRaw2 = obj.ReadSARScan(obj.savePath + "\radar2");
                if isempty(obj.sar.sarDataRaw2)
                    err = -1;
                    return;
                end
            end

            obj.textArea.Value = "Scan: " + obj.scanName + " loaded successfully!";
            err = 1;
        end

        function sarDataRaw = ReadSARScan(obj,savePath_temp)
            % Reads in the entire scan data for a single radar
            %
            % Outputs
            %   sarDataRaw  :   SAR data in numX x numY x numADC
            %   []          :   Error reading data

            if nargin < 2
                savePath_temp = obj.savePath;
            end

            % Create sarData array
            sarDataRaw = zeros(obj.numX,obj.nRx,obj.nTx,obj.numY,obj.numADC);

            % Load in each file and store in array
            for indFile = 1:obj.numY
                obj.textArea.Value = "Reading file #" + indFile;
                filePath = savePath_temp + "\" + obj.scanName + "_" + indFile + "_Raw_0.bin";
                tempData = obj.ReadFile(filePath);

                % Check Data
                if isempty(tempData)
                    sarDataRaw = [];
                    return;
                end

                % Flip Data if Two Direction Scanning
                if obj.sar.isTwoDirectionScanning && ~mod(indFile,2)
                    tempData = flip(tempData,4);
                end

                sarDataRaw(:,:,:,indFile,:) = permute(tempData(:,:,1,:,:),[4,1,2,3,5]);
                obj.textArea.Value = "Loaded file #" + indFile;
                drawnow;
            end
        end

        function data = ReadFile(obj,filePath)
            % Reads the data from a single file in the shape:
            % nRx x nTx x numChirps x numX x numADC
            %
            % If there is an error in reading the data, returns an empty
            % array []

            data = zeros(obj.nRx,obj.nTx,obj.numChirps,obj.numX,obj.numADC);

            fid = fopen(filePath);

            adcDataSize = 2*obj.numADC;
            try
                for indFrame = 1:obj.numX
                    for indChirp = 1:obj.numChirps
                        for indTx = 1:obj.nTx
                            for indRx = 1:obj.nRx
                                % Read the data
                                dataChunk = fread(fid,adcDataSize,'uint16','l');
%                                 dataChunk = fread(fid,adcDataSize,'uint16');
                                dataChunk = dataChunk - (dataChunk >= 2^15)*2^16;
                                adcOut = dataChunk(2:2:end) + 1j*dataChunk(1:2:end);
                                data(indRx,indTx,indChirp,indFrame,:) = adcOut;
                            end
                        end
                    end
                end
            catch
                obj.textArea.Value = "Error loading file at: " + filePath;
                warning("Error loading file at: " + filePath)
                fclose(fid);
                data = [];
                return
            end

            fclose(fid);
        end

        function err = VerifyFile(obj,filePath)
            % Verifies that the file has the expected size
            %
            % Outputs
            %   1   :   File does have expected size
            %   -1  :   File does not have expected size!
            %   0   :   File does not have expected size, but is too large
            
            % Check if file exists
            if ~exist(filePath,"file")
                err = -1;
                return;
            end
            
            expectedSize = 4*obj.nTx*obj.nRx*obj.numADC*obj.numChirps*obj.numX;
            if dir(filePath).bytes > expectedSize
                obj.textArea.Value = "Warning: " + filePath + " file size is too large!";
                warning("Warning: " + filePath + " file size is too large!");
                err = 0;
                return
            elseif dir(filePath).bytes < expectedSize
                obj.textArea.Value = "ERROR: " + filePath + " file size is too SMALL!";
                warning("ERROR: " + filePath + " file size is too SMALL!")
                err = -1;
                return
            end
            err = 1;
        end

        function err = VerifyScanFiles(obj,savePath_temp)
            % Verifies that the scan was completed and every file has the
            % expected size
            %
            % Outputs
            %   1   :   Successfully verified the entire scan
            %   -1  :   Could not verify the scan

            if nargin < 2
                savePath_temp = obj.savePath;
            end

            % Check files
            for indFile = 1:obj.numY
                filePath = savePath_temp + "\" + obj.scanName + "_" + indFile + "_Raw_0.bin";
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
            err = 1;
        end

        function err = VerifyScan(obj)
            % Verifies that the scan was completed for all radars
            %
            % Outputs
            %   1   :   Successfully verified the entire scan
            %   -1  :   Could not verify the scan

            if obj.sar.radarSelect == 1 || obj.sar.radarSelect == 2
                % Verify files
                if obj.VerifyScanFiles() == -1
                    err = -1;
                    return;
                end
            elseif obj.sar.radarSelect == 3
                % Verify files for radar 1
                if obj.VerifyScanFiles(obj.savePath + "\radar1") == -1
                    err = -1;
                    return;
                end

                % Verify files for radar 2
                if obj.VerifyScanFiles(obj.savePath + "\radar2") == -1
                    err = -1;
                    return;
                end
            end

            obj.textArea.Value = "Verified scan files successfully!";
            err = 1;
        end

        function err = CreateCalibrationData(obj,radar)
            % Creates the calibration for each radar, if the calibration
            % data for the radar with given serial number exists on the
            % path
            %
            % Outputs
            %   1   :   Successfully created calibration data
            %   -1  :   Could not create calibration data

            % Create calibration data for radar
            if exist("./cal/cal" + radar.num + "_" + sprintf("%.4d",radar.serialNumber) + ".mat",'file')
                load("./cal/cal" + radar.num + "_" + sprintf("%.4d",radar.serialNumber),'zBias_m','calData','mult2monoConst','sarDataEmpty');
                k = reshape(obj.("fmcw" + radar.num).k,1,1,[]);
                obj.sar.("calData" + radar.num) = permute(calData .* exp(1j*2*k*zBias_m),[4,1,2,5,3]);
                obj.sar.("mult2monoData" + radar.num) = permute(exp(-1j*k.*mult2monoConst),[4,1,2,5,3]);
                obj.sar.("sarDataEmpty" + radar.num) = permute(sarDataEmpty,[4,1,2,5,3]);
                
                % Calibrate data                
                obj.sar.("sarDataCal" + radar.num) = obj.sar.("calData" + radar.num) .* obj.sar.("mult2monoData" + radar.num) .* (obj.sar.("sarDataRaw" + radar.num) - obj.sar.("sarDataEmpty" + radar.num));
            else
                err = -1;
                obj.textArea.Value = "Warning: could not load radar " + radar.num + " calibration data";
                return
            end

            err = 1;
        end
    end
end