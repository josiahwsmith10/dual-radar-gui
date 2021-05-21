classdef SAR_Scanner_Device < handle
    properties
        textArea            % Text area in the GUI for showing statuses
        xField              % Edit field in the GUI for current x-position
        yField              % Edit field in the GUI for current y-position
        tField              % Edit field in the GUI for current rotation-positon
        scanTimeField       % Edit field in the GUI for scanning time
        motionController    % Motion controller (either AMC4030_Device or Drawer_Device
        
        xStep_m             % Step size in the x-direction in m
        yStep_m             % Step size in the y-direction in m
        tStep_deg           % Step size in the rotation-direction in deg
        
        numX                % Number of x steps
        numY                % Number of y steps
        numT                % Number of rotation steps
        
        xSize_m             % Aperture size in the x-direction in m
        ySize_m             % Aperture size in the y-direction in m
        tSize_deg           % Aperture size in the rotation-direction in deg
        
        lambda_m            % Wavelength of center frequency in m
        
        isScanning = false  % Boolean whether or not the scan is in progress
        isTwoDirection      % Boolean whether or not to do back and forth (two-direction) scanning
        
        pauseTol_s = 0.5    % Additional tolerance to wait for the horizontal scan in s
        scanTime_min        % Scan time in min
        
        method              % Type of scan, e.g. "Rectilinear"
    end
    
    methods
        function obj = SAR_Scanner_Device(app,motionController,fc_GHz)
            if ~isempty(app)
                obj.textArea = app.MainTextArea;
            end
            obj.motionController = motionController;
            
            obj.lambda_m = 299792458/(fc_GHz*1e9);
        end
        
        function obj = Configure(obj)
            if Verify(obj) == -1
                return;
            end
            
            switch obj.method
                case "Rectilinear"
                    obj = VerifyRectilinear(obj);
                otherwise
                    
            end
        end
        
        function obj = Start(obj)
            if Verify(obj) == -1
                return;
            end
            
            switch obj.method
                case "Rectilinear"
                    obj = VerifyRectilinear(obj);
                    obj = RectilinearScan(obj);
                otherwise
                    obj.textArea.Value = "ERROR: method must be one of the supported scan-types";
                    disp(obj.textArea.Value)
            end
        end
        
        function err = Verify(obj)
            % Ensures that the scan sizes are appropriate given the
            % parameters
            %
            % Outputs
            %   1   :   Successfully Verified Parameters
            %   -1  :   Paramters are Invalid
            
            err = 1;
            if obj.xStep_m*obj.numX > obj.xSize_m
                obj.textArea.Value = "ERROR: X steps exceed total size!";
                disp(obj.textArea.Value)
                err = -1;
            end
            if obj.yStep_m*obj.numY > obj.ySize_m
                obj.textArea.Value = "ERROR: Y steps exceed total size!";
                disp(obj.textArea.Value)
                err = -1;
            end
            if obj.tStep_deg*obj.numT > obj.tSize_deg
                obj.textArea.Value = "ERROR: Rotation steps exceed total size!";
                disp(obj.textArea.Value)
                err = -1;
            end
        end
        
        function obj = VerifyRectilinear(obj)
            % TODO: add timing for two-direction scanning
            obj.scanTime_min = ((obj.numY-1)*abs(obj.yStep_m*1e3/obj.motionController.ver_speed_mms) +...
                obj.numY*(2*obj.pauseTol_s + abs(obj.xSize_m*1e3/obj.motionController.hor_speed_mms)))/60;
            
            obj.scanTimeField = obj.scanTime_min;
        end
        
        function obj = RectilinearScan(obj)
            if ~obj.motionController.isConnected
                obj.textArea.Value = "ERROR: Connect motionController before starting scan!";
                disp(obj.textArea.Value)
                return;
            end
            
            if obj.isScanning
                obj.textArea.Value = "Scan is already in progress. Wait for it to finish before attempting another scan!";
                disp(obj.textArea.Value)
                return;
            end
            
            obj.isScanning = true;
            obj.textArea.Value = "Starting Rectilinear SAR Scan!";
            disp(obj.textArea.Value)
            
            % Save the initial position in x and y
            initial_x_mm = obj.motionController.curr_hor_mm;
            initial_y_mm = obj.motionController.curr_ver_mm;
            
            % Start the main loop
            for indY = 1:obj.numY
                obj.textArea.Value = "Iteration #" + indY + "/" + obj.numY;
                disp(obj.textArea.Value)
                
                % Do the horizontal movement
                [err,wait_time] = obj.motionController.Move_Horizontal(obj.xSize_m*1e3);
                if err ~= -1
                    pause(wait_time);
                else
                    obj.textArea.Value = "ERROR! Horizontal movement #" + indY + " failed!! Aborting scan";
                    disp(obj.textArea.Value)
                    obj.isScanning = false;
                    return;
                end
                
                pause(obj.pauseTol_s)
                
                % Different routine for the final scan
                if indY == obj.numY
                    obj.xSize_m = abs(obj.xSize_m);
                    break;
                end
                
                % Do the vertical movement
                [err,wait_time] = obj.motionController.Move_Vertical(obj.yStep_m*1e3);
                if err ~= -1
                    pause(wait_time);
                else
                    obj.textArea.Value = "ERROR! Vertical movement #" + indY + " failed!! Aborting scan";
                    disp(obj.textArea.Value)
                    obj.isScanning = false;
                    return;
                end
                
                if obj.isTwoDirection
                    obj.xSize_m = -obj.xSize_m;
                else
                    % TODO: make return speed faster to increase speed
                    % Do the horizontal movement
                    temp_hor_speed_mms = obj.motionController.hor_speed_mms;
                    obj.motionController.hor_speed_mms = obj.motionController.hor_speed_max_mms;
                    [err,wait_time] = obj.motionController.Move_Horizontal(-obj.xSize_m*1e3);
                    obj.motionController.hor_speed_mms = temp_hor_speed_mms;
                    if err ~= -1
                        obj.textArea.Value = "Returning to original horizontal position";
                        disp(obj.textArea.Value)
                        pause(wait_time);
                    else
                        obj.textArea.Value = "ERROR! Horizontal movement (returning to initial position) #" + indY + " failed!! Aborting scan";
                        disp(obj.textArea.Value)
                        obj.isScanning = false;
                        return;
                    end
                    pause(obj.pauseTol_s);
                end
            end
            
            % Move back to initial position
            [err,wait_time_hor] = obj.motionController.Move_Horizontal(initial_x_mm - obj.motionController.curr_hor_mm);
            if err == -1
                obj.textArea.Value = "ERROR! Horizontal movement (returning to initial position) failed!!";
                disp(obj.textArea.Value)
            end
            
            [err,wait_time_ver] = obj.motionController.Move_Vertical(initial_y_mm - obj.motionController.curr_ver_mm);
            if err == -1
                obj.textArea.Value = "ERROR! Vertical movement (returning to initial position) failed!!";
                disp(obj.textArea.Value)
            end
            
            pause(max([wait_time_hor,wait_time_ver]));
            obj.isScanning = false;
            obj.textArea.Value = "Rectilinear Scan Done!";
            disp(obj.textArea.Value)
        end
    end
end