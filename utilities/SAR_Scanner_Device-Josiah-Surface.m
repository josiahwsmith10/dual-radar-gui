classdef SAR_Scanner_Device < handle
    properties
        textArea            % Text area in the GUI for showing statuses
        xField              % Edit field in the GUI for current x-position
        yField              % Edit field in the GUI for current y-position
        tField              % Edit field in the GUI for current rotation-positon
        
        motionController    % Motion controller (either AMC4030_Device or Drawer_Device)
        sync                % Radar-scanner synchronizer microcontroller (ESP32_Device)
        radar1              % Radar 1 (TI_Radar_Device)
        radar2              % Radar 2 (TI_Radar_Device)
        dca1                % DCA1000EVM for radar 1 (DCA1000EVM_Device)
        dca2                % DCA1000EVM for radar 2 (DCA1000EVM_Device)
        
        fileName = "scan0"  % File name to save data to (without extension)
        
        xStep_m = 0         % Step size in the x-direction in m
        yStep_m = 0         % Step size in the y-direction in m
        tStep_deg = 0       % Step size in the rotation-direction in deg
        
        numX = 0            % Number of x steps
        numY = 0            % Number of y steps
        numT = 0            % Number of rotation steps
        
        isConfigured = 0    % Boolean whether or not the scan has been configured
        radarSelect = 1     % Radar selection (1 = radar 1 only, 2 = radar 2 only, 3 = radar 1 and radar 2)
        
        xMove_m = 0         % Size to move the radar platform in m
        DeltaX_m = 0        % Separation between radars in the x-direction in m
        xOffset_m = 0       % Offset in the x-direction in m
        
        xMax_m              % Maximum allowable distance in the x-direction in m
        yMax_m              % Maximum allowable distance in the y-direction in m
        
        xSize_m = 0         % Aperture size in the x-direction in m
        ySize_m = 0         % Aperture size in the y-direction in m
        tSize_deg = 0       % Aperture size in the rotation-direction in deg
        
        lambda_m = 0        % Wavelength of center frequency in m
        
        isScanning = false  % Boolean whether or not the scan is in progress
        isTwoDirection = 1  % Boolean whether or not to do back and forth (two-direction) scanning
        
        pauseTol_s = 0.5    % Additional tolerance to wait for the horizontal scan in s
        scanTime_min = 0    % Scan time in min
        
        method = ""         % Type of scan, e.g. "Rectilinear"
    end
    
    methods
        function obj = SAR_Scanner_Device(app,fc_GHz)
            if ~isempty(app)
                obj.textArea = app.MainTextArea;
            end
            
            obj.lambda_m = 299792458/(fc_GHz*1e9);
            
            obj.sync = ESP32_Device(app);
        end
        
        function obj = Configure(obj)
            % Configures the SAR_Scanner_Device
            
            if ~obj.motionController.isConfigured
                obj.textArea.Value = "Warning: Motion Controller is not configured yet!";
            end
            
            if ~obj.sync.isConfigured
                obj.textArea.Value = "Warning: Synchronizer is not configured yet!";
            end
            
            if Verify(obj) == -1
                obj.isConfigured = false;
                obj.textArea.Value = "Could not configure scan. Cannot verify parameters";
                return;
            end
            
            obj.isConfigured = true;
            obj.textArea.Value = "Scan configured";
        end
        
        function obj = Start(obj)
            % Verifies the parameters and starts the SAR scan
            
            obj.Configure();
            
            if ~obj.isConfigured
                obj.textArea.Value = "ERROR: scanner is not configured. Configure prior to starting a scan";
                return;
            end
            
            if Verify(obj) == -1
                return;
            end
            
            switch obj.method
                case "Rectilinear"
                    obj.RectilinearScan();
                otherwise
                    obj.textArea.Value = "ERROR: method must be one of the supported scan-types";
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
                    if VerifyRectilinear(obj) == -1
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
            
            % Time in minutes for two direction scanning
            obj.scanTime_min = ((obj.numY-1)*obj.yStep_m*1e3/obj.motionController.ver_speed_mms + ...
                obj.numY*(obj.pauseTol_s + obj.xMove_m*1e3/obj.motionController.hor_speed_mms))/60;
            
            err = 1;
            obj.textArea.Value = "Successfully verified rectilinear scan";
        end
        
        function obj = SingleCommand(obj,xMove_mm,yMove_mm)
            
            if ~obj.motionController.isConnected
                obj.textArea.Value = "ERROR: Connect motion controller before starting scan!";
                return;
            end
            if ~obj.motionController.isConfigured
                obj.textArea.Value = "ERROR: Configure motion controller before starting scan!";
                return;
            end
            
            if obj.isScanning
                obj.textArea.Value = "Scan is already in progress. Wait for it to finish before attempting single movement!";
                return;
            end
            
            [err,wait_time_hor] = obj.motionController.Move_Horizontal(xMove_mm,obj.xField);
            if err == -1
                obj.textArea.Value = "ERROR! Horizontal movement failed!!";
            end
            
            [err,wait_time_ver] = obj.motionController.Move_Vertical(yMove_mm,obj.yField);
            if err == -1
                obj.textArea.Value = "ERROR! Vertical movement failed!!";
            end
            
            pause(max([wait_time_hor,wait_time_ver]));
        end
        
        function obj = RectilinearScanOLD(obj)
            % Performs the Rectilinear Scan
            
            if ~obj.motionController.isConnected
                obj.textArea.Value = "ERROR: Connect motion controller before starting scan!";
                return;
            end
            if ~obj.motionController.isConfigured
                obj.textArea.Value = "ERROR: Configure motion controller before starting scan!";
                return;
            end
            
            if ~obj.sync.isConnected
                obj.textArea.Value = "ERROR: Connect synchronizer before starting scan!";
                return;
            end
            
            if ~obj.sync.isConfigured
                obj.textArea.Value = "ERROR: Configure synchronizer before starting scan!";
                return;
            end
            
            if ~obj.isConfigured
                obj.textArea.Value = "ERROR: Configure scan before starting scan!";
                return;
            end
            
            % Check radar 1 connection
            if (obj.radarSelect == 1 || obj.radarSelect == 3) && ~obj.radar1.isConnected
                obj.textArea.Value = "ERROR: Connect radar 1 before starting scan!";
                return;
            end
            
            % Check radar 1 configuration
            if (obj.radarSelect == 1 || obj.radarSelect == 3) && ~obj.radar1.isConfigured
                obj.textArea.Value = "ERROR: Configure radar 1 before starting scan!";
                return;
            end
            
            % Check radar 2 connection
            if (obj.radarSelect == 2 || obj.radarSelect == 3) && ~obj.radar2.isConnected
                obj.textArea.Value = "ERROR: Connect radar 2 before starting scan!";
                return;
            end
            
            % Check radar 2 configuration
            if (obj.radarSelect == 2 || obj.radarSelect == 3) && ~obj.radar2.isConfigured
                obj.textArea.Value = "ERROR: Configure radar 2 before starting scan!";
                return;
            end
            
            if obj.isScanning
                obj.textArea.Value = "Scan is already in progress. Wait for it to finish before attempting another scan!";
                return;
            end
            
            if obj.sync.SendStart() ~= 1
                obj.isScanning = false;
                return
            end
            
            obj.isScanning = true;
            obj.textArea.Value = "Starting Rectilinear SAR Scan!";
            
            % Save the initial position in x and y
            initial_x_mm = obj.motionController.curr_hor_mm;
            initial_y_mm = obj.motionController.curr_ver_mm;
            
            xMove_mm = obj.xMove_m*1e3;
            
            if obj.radarSelect == 1 || obj.radarSelect == 3
                obj.dca1.fileName = obj.fileName + "_" + 1;
                obj.dca1.Prepare();
                obj.dca1.Start();
                obj.radar1.Start();
            end
            
            if obj.radarSelect == 2 || obj.radarSelect == 3
                obj.dca2.fileName = obj.fileName + "_" + 1;
                obj.dca2.Prepare();
                obj.dca2.Start();
                obj.radar2.Start();
            end
            
            % Start the main loop
            for indY = 1:obj.numY
                %                 if obj.radarSelect == 1 || obj.radarSelect == 3
                %                     obj.dca1.fileName = obj.fileName + "_" + indY;
                %                     obj.dca1.Prepare();
                %                     obj.dca1.Start();
                %                     obj.radar1.Start();
                %                 end
                %
                %                 if obj.radarSelect == 2 || obj.radarSelect == 3
                %                     obj.dca2.fileName = obj.fileName + "_" + indY;
                %                     obj.dca2.Prepare();
                %                     obj.dca2.Start();
                %                     obj.radar2.Start();
                %                 end
                
                pause(obj.pauseTol_s)
                
                obj.textArea.Value = "Iteration #" + indY + "/" + obj.numY;
                
                [err,wait_time] = obj.motionController.Move_Horizontal(xMove_mm,obj.xField);
                if err ~= -1
                    pause(wait_time);
                else
                    obj.textArea.Value = "ERROR! Horizontal movement #" + indY + " failed!! Aborting scan";
                    obj.isScanning = false;
                    return;
                end
                
                pause(obj.pauseTol_s)
                
                
                if obj.radarSelect == 1 || obj.radarSelect == 3
                    obj.radar1.Stop();
                    obj.dca1.Stop();
                end
                
                if obj.radarSelect == 2 || obj.radarSelect == 3
                    obj.radar2.Stop();
                    obj.dca2.Stop();
                end
                
                % Different routine for the final scan
                if indY == obj.numY
                    obj.xSize_m = abs(obj.xSize_m);
                    break;
                end
                
                % Check if ESP32 completed the correct number of triggers
                if obj.sync.CheckHorDone() ~= 1
                    obj.isScanning = false;
                    return;
                end
                
                % Do the vertical movement
                [err,wait_time] = obj.motionController.Move_Vertical(obj.yStep_m*1e3,obj.yField);
                if err ~= -1
                    pause(wait_time);
                else
                    obj.textArea.Value = "ERROR! Vertical movement #" + indY + " failed!! Aborting scan";
                    obj.isScanning = false;
                    return;
                end
                
                if obj.radarSelect == 1 || obj.radarSelect == 3
                    obj.dca1.fileName = obj.fileName + "_" + (indY+1);
                    obj.dca1.Prepare();
                    obj.dca1.Start();
                    obj.radar1.Start();
                end
                
                if obj.radarSelect == 2 || obj.radarSelect == 3
                    obj.dca2.fileName = obj.fileName + "_" + (indY+1);
                    obj.dca2.Prepare();
                    obj.dca2.Start();
                    obj.radar2.Start();
                end
                
                % Send sarNext command to ESP32 to start next horizontal
                % movement
                if obj.sync.SendNext() ~= 1
                    obj.isScanning = false;
                    return;
                end
                
                if obj.isTwoDirection
                    xMove_mm = -xMove_mm;
                else
                    % NOT ALLOWED WITH ESP32!
                    obj.textArea.Value = "MUST USE TWO DIRECTION SCANNING WITH ESP32!";
                    obj.isScanning = false;
                    return;
                end
            end
            
            % Send sarNext command to ESP32 to end
            if obj.sync.SendNext() ~= 1
                obj.isScanning = false;
                return;
            end
            
            % Move back to initial position
            [err,wait_time_hor] = obj.motionController.Move_Horizontal(initial_x_mm - obj.motionController.curr_hor_mm,obj.xField);
            if err == -1
                obj.textArea.Value = "ERROR! Horizontal movement (returning to initial position) failed!!";
            end
            
            [err,wait_time_ver] = obj.motionController.Move_Vertical(initial_y_mm - obj.motionController.curr_ver_mm,obj.yField);
            if err == -1
                obj.textArea.Value = "ERROR! Vertical movement (returning to initial position) failed!!";
            end
            
            pause(max([wait_time_hor,wait_time_ver]));
            % Check if ESP32 completed the correct number of triggers
            if obj.sync.CheckScanDone() ~= 1
                obj.isScanning = false;
                return;
            end
            
            obj.isScanning = false;
            obj.textArea.Value = "Rectilinear Scan Done!";
        end
        
        
        function obj = RectilinearScan(obj)
            % Performs the Rectilinear Scan
            
            if ~obj.motionController.isConnected
                obj.textArea.Value = "ERROR: Connect motion controller before starting scan!";
                return;
            end
            if ~obj.motionController.isConfigured
                obj.textArea.Value = "ERROR: Configure motion controller before starting scan!";
                return;
            end
            
            if ~obj.sync.isConnected
                obj.textArea.Value = "ERROR: Connect synchronizer before starting scan!";
                return;
            end
            
            if ~obj.sync.isConfigured
                obj.textArea.Value = "ERROR: Configure synchronizer before starting scan!";
                return;
            end
            
            if ~obj.isConfigured
                obj.textArea.Value = "ERROR: Configure scan before starting scan!";
                return;
            end
            
%             % Check radar 1 connection
%             if (obj.radarSelect == 1 || obj.radarSelect == 3) && ~obj.radar1.isConnected
%                 obj.textArea.Value = "ERROR: Connect radar 1 before starting scan!";
%                 return;
%             end
%             
%             % Check radar 1 configuration
%             if (obj.radarSelect == 1 || obj.radarSelect == 3) && ~obj.radar1.isConfigured
%                 obj.textArea.Value = "ERROR: Configure radar 1 before starting scan!";
%                 return;
%             end
%             
%             % Check radar 2 connection
%             if (obj.radarSelect == 2 || obj.radarSelect == 3) && ~obj.radar2.isConnected
%                 obj.textArea.Value = "ERROR: Connect radar 2 before starting scan!";
%                 return;
%             end
%             
%             % Check radar 2 configuration
%             if (obj.radarSelect == 2 || obj.radarSelect == 3) && ~obj.radar2.isConfigured
%                 obj.textArea.Value = "ERROR: Configure radar 2 before starting scan!";
%                 return;
%             end
            
            % Check if scan is already in progress
            if obj.isScanning
                obj.textArea.Value = "Scan is already in progress. Wait for it to finish before attempting another scan!";
                return;
            end
            
            % Send start command to synchronizer
            if obj.sync.SendStart() ~= 1
                obj.isScanning = false;
                return
            end
            
            % Indicate scan is starting
            obj.isScanning = true;
            obj.textArea.Value = "Starting Rectilinear SAR Scan!";
            
            % Save the initial position in x and y
            initial_x_mm = obj.motionController.curr_hor_mm;
            initial_y_mm = obj.motionController.curr_ver_mm;
            
            xMove_mm = obj.xMove_m*1e3;
            
            % Start the main loop
            for indLap = 1:ceil(obj.numY/2)
                % Start radars
                obj.StartRadars(indLap*2-1);
                
                pause(obj.pauseTol_s)
                
                % Show iteration number on text area
                obj.textArea.Value = "Iteration #" + (indLap*2-1) + "/" + obj.numY;
                
                % Do the horizontal movement
                [err,wait_time] = obj.motionController.Move_Horizontal(xMove_mm,obj.xField);
                if err ~= -1
                    pause(wait_time);
                else
                    obj.textArea.Value = "ERROR! Horizontal movement #" + indY + " failed!! Aborting scan";
                    obj.isScanning = false;
                    return;
                end
                
                %pause(obj.pauseTol_s);
                
                % Check if ESP32 completed the correct number of triggers
                if obj.sync.CheckUpDone() ~= 1
                    obj.isScanning = false;
                    return;
                end
                
                % Stop the radars
                obj.StopRadars();
                
                pause(obj.pauseTol_s)
                
                % Do the vertical movement
                [err,wait_time] = obj.motionController.Move_Vertical(obj.yStep_m*1e3,obj.yField);
                if err ~= -1
                    pause(wait_time);
                else
                    obj.textArea.Value = "ERROR! Vertical movement #" + indY + " failed!! Aborting scan";
                    obj.isScanning = false;
                    return;
                end
                
                % Send sarNextUp command to ESP32 to start next horizontal
                % movement
                if obj.sync.SendNextUp() ~= 1
                    obj.isScanning = false;
                    return;
                end
                
                % Start the radars
                obj.StartRadars(indLap*2)
                
                pause(obj.pauseTol_s)
                
                % Show iteration number on text area
                obj.textArea.Value = "Iteration #" + indLap*2 + "/" + obj.numY;
                
                % Do the horizontal movement
                [err,wait_time] = obj.motionController.Move_Horizontal(-xMove_mm,obj.xField);
                if err ~= -1
                    pause(wait_time);
                else
                    obj.textArea.Value = "ERROR! Horizontal movement #" + indY + " failed!! Aborting scan";
                    obj.isScanning = false;
                    return;
                end
                
                %pause(obj.pauseTol_s);
                
                % Check if ESP32 completed the correct number of triggers
                if obj.sync.CheckDownDone() ~= 1
                    obj.isScanning = false;
                    return;
                end
                
                % Stop the radars
                obj.StopRadars();
                
                pause(obj.pauseTol_s)
                
                % If we are on the last iteration, exit immediately
                if indLap == ceil(obj.numY/2)
                    break
                end
                
                % Do the vertical movement
                [err,wait_time] = obj.motionController.Move_Vertical(obj.yStep_m*1e3,obj.yField);
                if err ~= -1
                    pause(wait_time);
                else
                    obj.textArea.Value = "ERROR! Vertical movement #" + indY + " failed!! Aborting scan";
                    obj.isScanning = false;
                    return;
                end
                
                % Send sarNextDown command to ESP32 to start next horizontal
                % movement
                if obj.sync.SendNextDown() ~= 1
                    obj.isScanning = false;
                    return;
                end
            end
            
            % Check if ESP32 completed the correct number of triggers
            if obj.sync.CheckScanDone() ~= 1
                obj.isScanning = false;
                return;
            end
            
            % Move back to initial position
            [err,wait_time_hor] = obj.motionController.Move_Horizontal(initial_x_mm - obj.motionController.curr_hor_mm,obj.xField);
            if err == -1
                obj.textArea.Value = "ERROR! Horizontal movement (returning to initial position) failed!!";
            end
            
            [err,wait_time_ver] = obj.motionController.Move_Vertical(initial_y_mm - obj.motionController.curr_ver_mm,obj.yField);
            if err == -1
                obj.textArea.Value = "ERROR! Vertical movement (returning to initial position) failed!!";
            end
            
            pause(max([wait_time_hor,wait_time_ver]));
            
            obj.isScanning = false;
            obj.textArea.Value = "Rectilinear Scan Done!";
        end
        
        function StartRadars(obj,ind)
%             if obj.radarSelect == 1 || obj.radarSelect == 3
%                 obj.dca1.fileName = obj.fileName + "_" + ind;
%                 obj.dca1.Prepare();
%                 obj.dca1.Start();
%                 obj.radar1.Start();
%             end
%             
%             if obj.radarSelect == 2 || obj.radarSelect == 3
%                 obj.dca2.fileName = obj.fileName + "_" + ind;
%                 obj.dca2.Prepare();
%                 obj.dca2.Start();
%                 obj.radar2.Start();
%             end
        end
        
        function StopRadars(obj)
%             if obj.radarSelect == 1 || obj.radarSelect == 3
%                 obj.radar1.Stop();
%                 obj.dca1.Stop();
%             end
%             
%             if obj.radarSelect == 2 || obj.radarSelect == 3
%                 obj.radar2.Stop();
%                 obj.dca2.Stop();
%             end
        end
    end
end