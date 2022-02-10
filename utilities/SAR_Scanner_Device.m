classdef SAR_Scanner_Device < handle
    properties
        amc                     % Motion controller (AMC4030_Device)
        esp                     % Radar-scanner synchronizer microcontroller (ESP32_Device handle)
        radar1                  % Radar 1 (TI_Radar_Device handle)
        radar2                  % Radar 2 (TI_Radar_Device handle)
        dca1                    % DCA1000EVM for radar 1 (DCA1000EVM_Device handle)
        dca2                    % DCA1000EVM for radar 2 (DCA1000EVM_Device handle)
        
        fileName = "scan0"      % File name to save data to (without extension)
        savePath = ""           % Folder containing the raw .bin files
        radarSelect = 1         % Radar selection (1 = radar 1 only, 2 = radar 2 only, 3 = radar 1 and radar 2)
        
        xStep_m = 0             % Step size in the x-direction in m
        yStep_m = 0             % Step size in the y-direction in m
        tStep_deg = 0           % Step size in the rotation-direction in deg
        pri_ms = 0              % Time between triggers in ms at maximum speed of the scan
        
        numX = 0                % Number of x steps
        numY = 0                % Number of y steps
        numT = 0                % Number of rotation steps
        
        xMove_m = 0             % Size to move the radar platform in m
        DeltaX_m = 0            % Separation between radars in the x-direction in m
        xOffset_m = 0           % Offset in the x-direction in m
        
        xMax_m                  % Maximum allowable distance in the x-direction in m
        yMax_m                  % Maximum allowable distance in the y-direction in m
        
        xSize_m = 0             % Aperture size in the x-direction in m
        ySize_m = 0             % Aperture size in the y-direction in m
        tSize_deg = 0           % Aperture size in the rotation-direction in deg
        
        isApp = false           % Boolean whether or not to use the GUI functionality
        isConfigured = 0        % Boolean whether or not the scan has been configured
        isScanning = false      % Boolean whether or not the scan is in progress
        isTwoDirection = 1      % Boolean whether or not to do back and forth (two-direction) scanning
        
        pauseTol_s = 0.5        % Additional tolerance to wait for the horizontal scan in s
        scanTime_min = 0        % Scan time in min
        
        method = ""             % Type of scan, e.g. "Rectilinear"
        
        scanNotes               % Notes about the scan, for reference
        
        % GUI related parameters
        textArea                % Text area in the GUI for showing statuses
        app                     % GUI object handle
        
        % SAR scanner fields
        fileName_field          % Edit field in the GUI for fileName
        xStep_mm_field          % Edit field in the GUI for xStep in mm
        yStep_mm_field          % Edit field in the GUI for yStep in mm
        numX_field              % Edit field in the GUI for numX
        numY_field              % Edit field in the GUI for numY
        xMax_mm_field           % Edit field in the GUI for xMax in mm
        yMax_mm_field           % Edit field in the GUI for yMax in mm
        DeltaX_mm_field         % Edit field in the GUI for DeltaX in mm
        xOffset_mm_field        % Edit field in the GUI for xOffset in mm
        pri_ms_field            % Edit field in the GUI for the PRI in ms
        scanNotes_field         % Edit field in the GUI for the scan notes
        
        % SAR scanner fields for display
        xSize_mm_field          % Edit field in the GUI for xSize in mm
        ySize_mm_field          % Edit field in the GUI for ySize in mm
        scanTime_min_field      % Edit field in the GUI for scanTime_min
        
        % Radar 1 and 2 checkboxes
        isRadar1_checkbox       % Checkbox in GUI for radar1
        isRadar2_checkbox       % Checkbox in GUI for radar2
    end
    
    methods
        function obj = SAR_Scanner_Device()
        end
        
        function Update(obj)
            % Update the SAR_Scanner_Device
            
            if obj.isApp
                obj.Get();
            end
            
            obj.Verify();
            
            if obj.isApp
                obj.Display();
            end
        end
        
        function Get(obj)
            % Attempts to get the values from the GUI
            
            if ~obj.isApp
                obj.textArea.Value = "ERROR: isApp must be set to true to get the values!";
                return;
            end
            
            obj.fileName = obj.fileName_field.Value;
            
            obj.xStep_m = obj.xStep_mm_field.Value*1e-3;
            obj.yStep_m = obj.yStep_mm_field.Value*1e-3;
            
            obj.numX = obj.numX_field.Value;
            obj.numY = obj.numY_field.Value;
            
            r = mod(obj.numY,2);
            obj.numY = obj.numY + r;
            obj.numY_field.Value = obj.numY;
            
            obj.xMax_m = obj.xMax_mm_field.Value*1e-3;
            obj.yMax_m = obj.yMax_mm_field.Value*1e-3;
            
            obj.DeltaX_m = obj.DeltaX_mm_field.Value*1e-3;
            obj.xOffset_m = obj.xOffset_mm_field.Value*1e-3;
            
            obj.pri_ms = obj.pri_ms_field.Value;
            
            obj.radarSelect = obj.isRadar1_checkbox.Value + 2*obj.isRadar2_checkbox.Value;
            
            obj.scanNotes = obj.scanNotes_field.Value;
        end
        
        function Display(obj)
            % Attempt to display the values on the GUI
            
            if ~obj.isApp
                obj.textArea.Value = "ERROR: isApp must be set to true to display the values!";
                return;
            end
            
            obj.xSize_mm_field.Value = obj.xSize_m*1e3;
            obj.ySize_mm_field.Value = obj.ySize_m*1e3;
            obj.scanTime_min_field.Value = obj.scanTime_min;
            obj.pri_ms_field.Value = obj.pri_ms;
        end
        
        function Configure(obj)
            % Configures the SAR_Scanner_Device
            
            obj.amc.Configure();
            obj.esp.Configure();
            
            obj.Update();
            
            if obj.Verify() == -1
                obj.isConfigured = false;
                return;
            end
            
            obj.isConfigured = true;
            obj.textArea.Value = "Scan configured";
        end
        
        function Load(obj)
            obj.savePath = cd + "\data\" + obj.fileName;
            % Read in the data
            dataReader = Data_Reader(obj);
            if dataReader.GetScan() == -1
                return;
            end
            % Clean up - saves memory
            delete(dataReader);
        end
        
        function Start(obj)
            % Verifies the parameters and starts the SAR scan
            
            obj.Configure();
            
            if ~obj.isConfigured
                return;
            end
            
            if obj.Verify() == -1
                return;
            end
            
            switch obj.method
                case "Rectilinear"
                    isScanSuccess = obj.RectilinearScan();
                otherwise
                    obj.textArea.Value = "ERROR: method must be one of the supported scan-types";
                    return;
            end
            
            if isScanSuccess == 1
                obj.CreateScanNotes();
                obj.CreateLoadScanScript();
            end
        end
        
        function err = Verify(obj)
            % Ensures that the scan sizes are appropriate given the
            % parameters
            %
            % Outputs
            %   1   :   Successfully Verified Parameters
            %   -1  :   Paramters are Invalid
            
            switch obj.method
                case "Rectilinear"
                    if obj.VerifyRectilinear() == -1
                        err = -1;
                        return;
                    end
                otherwise
                    obj.textArea.Value = "ERROR: method must be one of the supported scan-types. Cannot verify scan";
                    err = -1;
                    return;
            end
            err = 1;
        end
        
        function err = VerifyRectilinear(obj)
            % Verifies the Rectilinear Scanning Parameters
            %
            % Outputs
            %   1   :   Successfully verified rectilinear parameters
            %   -1  :   Rectilinear parameters are invalid
            
            obj.xSize_m = (obj.numX-1)*obj.xStep_m;
            obj.ySize_m = (obj.numY-1)*obj.yStep_m;
            
            % Compute total distance to move the radar including end points
            if obj.radarSelect == 1
                obj.xMove_m = ceil(obj.xSize_m*1e3 + obj.xOffset_m*1e3 + 10)*1e-3;
            elseif obj.radarSelect == 3 || obj.radarSelect == 2
                obj.xMove_m = ceil(obj.xSize_m*1e3 + obj.xOffset_m*1e3 + obj.DeltaX_m*1e3 + 10)*1e-3;
            else
                err = -1;
                obj.textArea.Value = "ERROR: invalid radar selection!";
                return;
            end
            
            % If the total distance traveled in the x-direction exceeds the
            % maximum allowable distance
            if obj.xMove_m > obj.xMax_m
                err = -1;
                obj.textArea.Value = "ERROR: array size is too large in x-direction!";
                return;
            end
            
            % If the total distance traveled in the y-direction exceeds the
            % maximum allowable distance
            if obj.ySize_m > obj.yMax_m
                err = -1;
                obj.textArea.Value = "ERROR: array size is too large in y-direction!";
                return;
            end
            
            % If the period between pulses is less than the radar
            % periodicity
            obj.pri_ms = obj.xStep_m*1e3/(obj.amc.hor_speed_mms*1e-3);
            if obj.radarSelect == 1 || obj.radarSelect == 3
                if obj.radar1.pri_ms > obj.pri_ms
                    err = -1;
                    obj.textArea.Value = "ERROR: radar 1 periodicity is too large!";
                    return;
                end
            end
            if obj.radarSelect == 2 || obj.radarSelect == 3
                if obj.radar2.pri_ms > obj.pri_ms
                    err = -1;
                    obj.textArea.Value = "ERROR: radar 2 periodicity is too large!";
                    return;
                end
            end
            
            % Time in minutes for two direction scanning
            obj.scanTime_min = ((obj.numY-1)*obj.yStep_m*1e3/obj.amc.ver_speed_mms + ...
                obj.numY*(obj.pauseTol_s + obj.xMove_m*1e3/obj.amc.hor_speed_mms))/60;
            
            err = 1;
            obj.textArea.Value = "Successfully verified rectilinear scan";
        end
        
        function SingleCommand(obj,xMove_mm,yMove_mm)
            
            if ~obj.amc.isConnected
                obj.textArea.Value = "ERROR: Connect motion controller before attempting single movement!";
                return;
            end
            
            if ~obj.amc.isConfigured
                obj.textArea.Value = "ERROR: Configure motion controller before attempting single movement!";
                return;
            end
            
            if obj.isScanning
                obj.textArea.Value = "Scan is already in progress. Wait for it to finish before attempting single movement!";
                return;
            end
            
            [err,wait_time_hor] = obj.amc.Move_Horizontal(xMove_mm);
            if err == -1
                obj.textArea.Value = "ERROR! Horizontal movement failed!!";
            end
            
            [err,wait_time_ver] = obj.amc.Move_Vertical(yMove_mm);
            if err == -1
                obj.textArea.Value = "ERROR! Vertical movement failed!!";
            end
            
            pause(max([wait_time_hor,wait_time_ver]));
        end
        
        function err = RectilinearScan(obj)
            % Performs the Rectilinear Scan
            %
            % Outputs
            %   1   :   Scan completed successfully 
            %   -1  :   Scan was unsuccessful!
            
            % temp
            obj.pauseTol_s = 0.5;
            
            % Check AMC4030 is connected
            if ~obj.amc.isConnected
                obj.textArea.Value = "ERROR: Connect motion controller before starting scan!";
                err = -1;
                return;
            end
            
            % Check AMC4030 is configured
            if ~obj.amc.isConfigured
                obj.textArea.Value = "ERROR: Configure motion controller before starting scan!";
                err = -1;
                return;
            end
            
            % Check ESP32 is connected
            if ~obj.esp.isConnected
                obj.textArea.Value = "ERROR: Connect synchronizer before starting scan!";
                err = -1;
                return;
            end
            
            % Check ESP32 is configured
            if ~obj.esp.isConfigured
                obj.textArea.Value = "ERROR: Configure synchronizer before starting scan!";
                err = -1;
                return;
            end
            
            % Check AMC4030 is connected
            if ~obj.isConfigured
                obj.textArea.Value = "ERROR: Configure scan before starting scan!";
                err = -1;
                return;
            end
            
            % Check radar 1 connection
            if (obj.radarSelect == 1 || obj.radarSelect == 3) && ~obj.radar1.isConnected
                obj.textArea.Value = "ERROR: Connect radar 1 before starting scan!";
                err = -1;
                return;
            end
            
            % Check radar 1 configuration
            if (obj.radarSelect == 1 || obj.radarSelect == 3) && ~obj.radar1.isConfigured
                obj.textArea.Value = "ERROR: Configure radar 1 before starting scan!";
                err = -1;
                return;
            end
            
            % Check radar 2 connection
            if (obj.radarSelect == 2 || obj.radarSelect == 3) && ~obj.radar2.isConnected
                obj.textArea.Value = "ERROR: Connect radar 2 before starting scan!";
                err = -1;
                return;
            end
            
            % Check radar 2 configuration
            if (obj.radarSelect == 2 || obj.radarSelect == 3) && ~obj.radar2.isConfigured
                obj.textArea.Value = "ERROR: Configure radar 2 before starting scan!";
                err = -1;
                return;
            end
            
            % Check if scan is already in progress
            if obj.isScanning
                obj.textArea.Value = "Scan is already in progress. Wait for it to finish before attempting another scan!";
                err = -1;
                return;
            end
            
            % Check if scan name exists
            obj.savePath = cd + "\data\" + obj.fileName;
            if exist(obj.savePath,"dir")
                msg = "Scan titled: """ + obj.fileName + """ already exists! " +...
                    "Are you sure you would like to overwrite this scan?";
                title = "WARNING: Overwrite?";
                
                selection = uiconfirm(obj.app.UIFigure,msg,title,...
                    'Options',{'Yes','No'},...
                    'DefaultOption',2,'CancelOption',2,...
                    "Icon","warning");
                
                if selection == "No"
                    obj.textArea.Value = "Canceled scan: """ + obj.fileName + """";
                    err = -1;
                    return;
                end
                
                rmdir(obj.savePath,"s");
                
                if exist(obj.savePath + ".mat","file")
                    delete(obj.savePath + ".mat");
                end
            end
            
            % Create the Data_Reader to verify the files
            d = Data_Reader(obj);
                        
            % Send start command to synchronizer
            if obj.esp.SendStart() ~= 1
                obj.isScanning = false;
                err = -1;
                return
            end
            
            % Indicate scan is starting
            obj.isScanning = true;
            obj.textArea.Value = "Starting Rectilinear SAR Scan!";
            
            % Create directory to save files
            if ~exist(obj.savePath,'dir')
                mkdir(obj.savePath);
            end
            
            % Save the initial position in x and y
            initial_x_mm = obj.amc.curr_hor_mm;
            initial_y_mm = obj.amc.curr_ver_mm;
            
            xMove_mm = obj.xMove_m*1e3;
            
            % Start the main loop
            for indLap = 1:ceil(obj.numY/2)
                % Start radars
                obj.StartRadars(indLap*2-1);
                
                % Show iteration number on text area
                obj.textArea.Value = "Iteration #" + (indLap*2-1) + "/" + obj.numY;
                
                % Do the horizontal movement
                [err,wait_time] = obj.amc.Move_Horizontal(xMove_mm);
                if err ~= -1
                    pause(wait_time);
                else
                    obj.textArea.Value = "ERROR! Horizontal movement #" + indY + " failed!! Aborting scan";
                    err = obj.RectilinearExitScan(-1,initial_x_mm,initial_y_mm);
                    return;
                end
                
                % Check if ESP32 completed the correct number of triggers
                if obj.esp.CheckUpDone() ~= 1
                    err = obj.RectilinearExitScan(-1,initial_x_mm,initial_y_mm);
                    return;
                end
                
                pause(obj.pauseTol_s)
                
                % Check if data size is correct
                if obj.VerifySingleHorData(d,indLap*2-1) == -1
                    err = obj.RectilinearExitScan(-1,initial_x_mm,initial_y_mm);
                    return;
                end
                
                % Do the vertical movement
                [err,wait_time] = obj.amc.Move_Vertical(obj.yStep_m*1e3);
                if err ~= -1
                    pause(wait_time);
                else
                    obj.textArea.Value = "ERROR! Vertical movement #" + indY + " failed!! Aborting scan";
                    err = obj.RectilinearExitScan(-1,initial_x_mm,initial_y_mm);
                    return;
                end
                
                % Send sarNextUp command to ESP32 to start next horizontal
                % movement
                if obj.esp.SendNextUp() ~= 1
                    err = obj.RectilinearExitScan(-1,initial_x_mm,initial_y_mm);
                    return;
                end
                
                % Start the radars
                obj.StartRadars(indLap*2)
                
                % Show iteration number on text area
                obj.textArea.Value = "Iteration #" + indLap*2 + "/" + obj.numY;
                
                % Do the horizontal movement
                [err,wait_time] = obj.amc.Move_Horizontal(-xMove_mm);
                if err ~= -1
                    pause(wait_time);
                else
                    obj.textArea.Value = "ERROR! Horizontal movement #" + indY + " failed!! Aborting scan";
                    err = obj.RectilinearExitScan(-1,initial_x_mm,initial_y_mm);
                    return;
                end
                
                % Check if ESP32 completed the correct number of triggers
                if obj.esp.CheckDownDone() ~= 1
                    err = obj.RectilinearExitScan(-1,initial_x_mm,initial_y_mm);
                    return;
                end
                
                pause(obj.pauseTol_s)
                
                % Check if data size is correct
                if obj.VerifySingleHorData(d,indLap*2) == -1
                    err = obj.RectilinearExitScan(-1,initial_x_mm,initial_y_mm);
                    return;
                end
                
                % If we are on the last iteration, exit immediately
                if indLap == ceil(obj.numY/2)
                    break
                end
                
                % Do the vertical movement
                [err,wait_time] = obj.amc.Move_Vertical(obj.yStep_m*1e3);
                if err ~= -1
                    pause(wait_time);
                else
                    obj.textArea.Value = "ERROR! Vertical movement #" + indY + " failed!! Aborting scan";
                    err = obj.RectilinearExitScan(-1,initial_x_mm,initial_y_mm);
                    return;
                end
                
                % Send sarNextDown command to ESP32 to start next horizontal
                % movement
                if obj.esp.SendNextDown() ~= 1
                    err = obj.RectilinearExitScan(-1,initial_x_mm,initial_y_mm);
                    return;
                end
            end
            
            % Check if ESP32 completed the correct number of triggers
            if obj.esp.CheckScanDone() ~= 1
                err = obj.RectilinearExitScan(-1,initial_x_mm,initial_y_mm);
                return;
            end
            
            pause(obj.pauseTol_s*4)
                
            % Check if data size is correct for last horizontal scan
            if obj.VerifySingleHorData(d,indLap*2+1) == -1
                err = obj.RectilinearExitScan(-1,initial_x_mm,initial_y_mm);
                return;
            end
            
            err = obj.RectilinearExitScan(1,initial_x_mm,initial_y_mm);
            obj.textArea.Value = "Rectilinear Scan Done!";
        end
        
        function err = VerifySingleHorData(obj,d,ind)
            % Verifies that the file has the expected size for one
            % horizontal scan\
            %
            % Outputs
            %   1   :   File does have expected size
            %   -1  :   File does not have expected size!
            
            if ind == 1
                err = 1;
                return;
            else
                ind = ind - 1;
            end
            
            if obj.radarSelect == 1 || obj.radarSelect == 2
                filePath = cd + "\data\" + obj.fileName + "\" + obj.fileName + "_" + ind + "_Raw_0.bin";
                
                if d.VerifyFile(filePath) == -1
                    obj.textArea.Value = "Data at: " + filePath + " is invalid!";
                    err = -1;
                    return;
                end
            
                obj.textArea.Value = "Data is correct size!";
            elseif obj.radarSelect == 3
                filePath = cd + "\data\" + obj.fileName + "\radar1\" + obj.fileName + "_" + ind + "_Raw_0.bin";
                
                if d.VerifyFile(filePath) == -1
                    obj.textArea.Value = "Data at: " + filePath + " is invalid!";
                    err = -1;
                    return;
                end
                
                
                filePath = cd + "\data\" + obj.fileName + "\radar2\" + obj.fileName + "_" + ind + "_Raw_0.bin";
                
                if d.VerifyFile(filePath) == -1
                    obj.textArea.Value = "Data at: " + filePath + " is invalid!";
                    err = -1;
                    return;
                end
            
                obj.textArea.Value = "Data is correct size for radars 1 and 2!";
            end
            pause(0.1)
            err = 1;
        end
        
        function err = RectilinearExitScan(obj,err,initial_x_mm,initial_y_mm)
            % Exits the scan and moves the platform back to the initial
            % position
            
            if err == -1
                obj.isScanning = false;
                obj.esp.SendStop();
            elseif err == 1
                obj.isScanning = false;
            end
            
            obj.RectilinearReturnToInitialXY(initial_x_mm,initial_y_mm);
        end
        
        function RectilinearReturnToInitialXY(obj,initial_x_mm,initial_y_mm)
            % Move back to initial position
            
            [err,wait_time_hor] = obj.amc.Move_Horizontal(initial_x_mm - obj.amc.curr_hor_mm);
            if err == -1
                obj.textArea.Value = "ERROR! Horizontal movement (returning to initial position) failed!!";
            end
            
            [err,wait_time_ver] = obj.amc.Move_Vertical(initial_y_mm - obj.amc.curr_ver_mm);
            if err == -1
                obj.textArea.Value = "ERROR! Vertical movement (returning to initial position) failed!!";
            end
            
            pause(max([wait_time_hor,wait_time_ver]));
        end
        
        function StartRadars(obj,ind)
            pause(1)
            
            if obj.radarSelect == 1
                obj.dca1.folderName = obj.fileName;
                obj.dca1.fileName = obj.fileName + "_" + ind;
                obj.dca1.Prepare(true);
                obj.dca1.Start();
                pause(0.1)
                obj.radar1.Start();
            elseif obj.radarSelect == 2
                obj.dca2.folderName = obj.fileName;
                obj.dca2.fileName = obj.fileName + "_" + ind;
                obj.dca2.Prepare(true);
                obj.dca2.Start();
                pause(0.1)
                obj.radar2.Start();
            elseif obj.radarSelect == 3
                obj.dca1.folderName = obj.fileName + "\radar1";
                obj.dca1.fileName = obj.fileName + "_" + ind;
                
                obj.dca2.folderName = obj.fileName + "\radar2";
                obj.dca2.fileName = obj.fileName + "_" + ind;
                
                obj.dca1.Prepare(true);
                obj.dca2.Prepare(true);
                
                obj.dca1.Start();
                obj.dca2.Start();
                pause(0.1)
                obj.radar1.Start();
                obj.radar2.Start();
            end
        end
        
        function CreateLoadScanScript(obj)
            % Creates the script .m file to load in the data
            
            fid = fopen(cd + "\data\" + obj.fileName + "\load_" + obj.fileName + ".m","wt");
            
            if fid == -1
                obj.textArea.Value = "Error creating load scan script!";
                fclose(fid);
                return
            end
            
            % Print the load scan script string
            fprintf(fid,'%s\n',obj.createLoadScanScriptStr());
            
            fclose(fid);
            
            obj.savePath = cd + "\data\" + obj.fileName;
            scanner.savePath = obj.savePath;
            scanner.fileName = obj.fileName;
            
            scanner.numX = obj.numX;
            scanner.numY = obj.numY;
            scanner.isTwoDirection = obj.isTwoDirection;
            scanner.radarSelect = obj.radarSelect;
            
            scanner.radar1.adcSamples = obj.radar1.adcSamples;
            scanner.radar2.adcSamples = obj.radar2.adcSamples;
            
            scanner.radar1.nTx = obj.radar1.nTx;
            scanner.radar1.nRx = obj.radar1.nRx;
            scanner.radar2.nTx = obj.radar2.nTx;
            scanner.radar2.nRx = obj.radar2.nRx;
            
            scanner.radar1.fmcw = obj.radar1.fmcw;
            scanner.radar2.fmcw = obj.radar2.fmcw;
            
            scanner.radar1.ant = obj.radar1.ant;
            scanner.radar2.ant = obj.radar2.ant;
            
            scanner.radar1.num = obj.radar1.num;
            scanner.radar2.num = obj.radar2.num;
            
            scanner.radar1.serialNumber = obj.radar1.serialNumber;
            scanner.radar2.serialNumber = obj.radar2.serialNumber;
            
            scanner.xStep_m = obj.xStep_m;
            scanner.yStep_m = obj.yStep_m;
            scanner.textArea = [];
            scanner.scanNotes = obj.scanNotes;
            
            save(cd + "\data\" + obj.fileName + "\" + obj.fileName + "LoadFiles","scanner");
        end
        
        function str = createLoadScanScriptStr(obj)
            % Creates the script string
            
            str = [
                "%% Load Necessary Files"
                "addpath(genpath(""./data/ + obj.fileName""))"
                "load(""" + obj.fileName + "LoadFiles.mat"",""scanner"")"
                ""
                "%% Create Data_Reader"
                "d = Data_Reader(scanner);"
                ""
                "%% Load the Scanning Data"
                "d.GetScan();"
                ];
        end
        
        function CreateScanNotes(obj)
            % Creates the notes.txt file containing the scan notes
            
            fid = fopen(cd + "\data\" + obj.fileName + "\notes_" + obj.fileName + ".txt","wt");
            
            if fid == -1
                obj.textArea.Value = "Error creating scan notes!";
                fclose(fid);
                return
            end
            
            % Print the load scan script string
            fprintf(fid,'%s\n',obj.createScanNotesStr());
            
            fclose(fid);
        end
        
        function str = createScanNotesStr(obj)
            % Creates the scan notes string
            
            switch obj.method
                case "Rectilinear"
                    str = obj.createScanNotesStrRectilinear();
                otherwise
                    str = "";
                    return;
            end
        end
        
        function str = createScanNotesStrRectilinear(obj)
            % Creates the scan notes string for the rectilinear scanning
            % mode
            
            str = [
                "%% Scan Notes"
                "Name: " + obj.fileName
                "Location: " + "\data\" + obj.fileName
                ""
                sprintf("X-Step Size (mm):\t%1.7f",obj.xStep_m*1e3)
                sprintf("Y-Step Size (mm):\t%1.7f",obj.yStep_m*1e3)
                ""
                sprintf("Num X-Steps:\t\t%d",obj.numX)
                sprintf("Num Y-Steps:\t\t%d",obj.numY)
                ""
                sprintf("X-Aperture Size (mm):\t%f",obj.xSize_m*1e3)
                sprintf("Y-Aperture Size (mm):\t%f",obj.ySize_m*1e3)
                ""
                sprintf("Periodicity (ms):\t%f",obj.pri_ms)
                ""
                sprintf("Is radar 1:\t\t%d",obj.radarSelect == 1 || obj.radarSelect == 3)
                sprintf("Is radar 2:\t\t%d",obj.radarSelect == 2 || obj.radarSelect == 3)
                ""
                sprintf("X-Speed (mm/s)\t\t%d",obj.amc.hor_speed_mms)
                sprintf("Y-Speed (mm/s)\t\t%d",obj.amc.ver_speed_mms)
                ""
                sprintf("Delta-X (mm)\t\t%f",obj.DeltaX_m*1e3)
                sprintf("X-Offset(mm)\t\t%f",obj.xOffset_m*1e3)
                ""
                "User Notes:"
                regexprep(obj.scanNotes,'.{1,59}\s','$0\n')
                ];
        end
    end
end