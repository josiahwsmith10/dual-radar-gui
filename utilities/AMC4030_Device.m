classdef AMC4030_Device < handle
    properties
        isApp = false           % Boolean whether or not to use the GUI functionality
        isConnected = false     % Boolean whether or not the AMC4030 device is connected
        isConfigured = false    % Boolean whether or not the AMC4030 device is configured
        COMPortNum              % COM port number of the AMC4030
        
        patience = 10           % Number of attempts for movement in any direction before giving up, default = 10
        wait_tol = 0.001        % Tolerance for extra wait time (extra wait time = wait_tol*speed)
        
        hor_speed_mms = 20      % Speed of horizontal movement in mm/s
        ver_speed_mms = 20      % Speed of vertical movement in mm/s
        rot_speed_degs = 20     % Speed of rotational movement in deg/s
        
        hor_speed_max_mms = 50  % Maximum speed of horizontal movement in mm/s
        ver_speed_max_mms = 50  % Maximum speed of vertical movement in mm/s
        rot_speed_max_degs = 50 % Speed of rotational movement in deg/s
        
        hor_speed_home_mms = 20 % Homing speed of horizontal movement in mm/s
        ver_speed_home_mms = 20 % Homing speed of horizontal movement in mm/s
        
        hor_home_offset_mm = 0  % Horizontal home offset in mm
        ver_home_offset_mm = 0  % Vertical home offset in mm
        
        curr_hor_mm = 0         % Current horizontal position
        curr_ver_mm = 0         % Current vertical position
        curr_rot_deg = 0        % Current rotational position
        
        hor_max_mm = 500        % Maximum possible horizontal position in mm
        ver_max_mm = 500        % Maximum possible vertical position in mm
        
        hor_mm_per_rev          % Number of millimeters per revolution in the horizontal direction
        hor_pulses_per_rev      % Number of pulses per revolution in the horizontal direction
        ver_mm_per_rev          % Number of millimeters per revolution in the vertical direction
        ver_pulses_per_rev      % Number of pulses per revolution in the vertical direction
        rot_mm_per_rev          % Number of millimeters per revolution in the rotational direction
        rot_pulses_per_rev      % Number of pulses per revolution in the rotational direction
        
        configString            % String array holding every line of the
        configFilePath          % Path of the config file
        
        % GUI related parameters
        connectionLamp          % Lamp in the GUI for the AMC4030 connection
        configurationLamp       % Lamp in the GUI for the AMC4030 configuration
        textArea                % Text area in the GUI for showing statuses
        app                     % GUI object handle
        
        % AMC4030 fields
        hor_speed_field = struct("Value",[])         % Edit field in the GUI for the horizontal speed in mm/s
        ver_speed_field = struct("Value",[])         % Edit field in the GUI for the vertical speed in mm/s
        rot_speed_field = struct("Value",[])         % Edit field in the GUI for the rotational speed in mm/s
        hor_home_speed_field = struct("Value",[])    % Edit field in the GUI for the homing speed in mm/s of the horizontal direction
        hor_home_offset_field = struct("Value",[])   % Edit field in the GUI for the home offset in the horizontal direction
        ver_home_speed_field = struct("Value",[])    % Edit field in the GUI for the homing speed in mm/s of the vertical direction
        ver_home_offset_field = struct("Value",[])   % Edit field in the GUI for the home offset in the vertical direction
        hor_mm_rev_field = struct("Value",[])        % Edit field in the GUI for the mm/rev in the horizontal direction
        hor_pulses_rev_field = struct("Value",[])    % Edit field in the GUI for the pulses/rev in the horizontal direction
        ver_mm_rev_field = struct("Value",[])        % Edit field in the GUI for the mm/rev in the vertical direction
        ver_pulses_rev_field = struct("Value",[])    % Edit field in the GUI for the pulses/rev in the vertical direction
        rot_mm_rev_field = struct("Value",[])        % Edit field in the GUI for the mm/rev in the rotational direction
        rot_pulses_rev_field = struct("Value",[])    % Edit field in the GUI for the pulses/rev in the rotational direction
        curr_hor_field = struct("Value",[])          % Edit field in the GUI for current horizontal position in mm
        curr_ver_field = struct("Value",[])          % Edit field in the GUI for current vertical position in mm
        curr_rot_field = struct("Value",[])          % Edit field in the GUI for current rotational position in mm
        hor_max_field = struct("Value",[])           % Edit field in the GUI for the maximum horizontal position in mm
        ver_max_field = struct("Value",[])           % Edit field in the GUi for the maximum vertical position in mm
    end
    
    methods
        function obj = AMC4030_Device()
            % Note:
            % Horizontal    : X-Axis on AMC4030
            % Veritcal      : Y-Axis on AMC4030
            % Rotational    : Z-Axis on AMC4030
            
            obj.configFilePath = cd + "\include\drg_AMC4030_Config.ini";
        end
        
        function Update(obj)
            % Update the AMC4030_Device
            
            if obj.isApp
                obj.Get();
            end
        end
        
        function Get(obj)
            % Attempts to get the values from the GUI
            
            if ~obj.isApp
                obj.textArea.Value = "ERROR: isApp must be set to true to get the values!";
                return;
            end
            
            % Horizontal (Axis 0)
            obj.hor_speed_mms = obj.hor_speed_field.Value;
            obj.hor_speed_home_mms = obj.hor_home_speed_field.Value;
            obj.hor_home_offset_mm = obj.hor_home_offset_field.Value;
            obj.hor_max_mm = obj.hor_max_field.Value;
            
            obj.hor_mm_per_rev = obj.hor_mm_rev_field.Value;
            obj.hor_pulses_per_rev = obj.hor_pulses_rev_field.Value;
            
            % Vertical (Axis 1)
            obj.ver_speed_mms = obj.ver_speed_field.Value;
            obj.ver_speed_home_mms = obj.ver_home_speed_field.Value;
            obj.ver_home_offset_mm = obj.ver_home_offset_field.Value;
            obj.ver_max_mm = obj.ver_max_field.Value;
            
            obj.ver_mm_per_rev = obj.ver_mm_rev_field.Value;
            obj.ver_pulses_per_rev = obj.ver_pulses_rev_field.Value;
            
            % Rotational (Axis 2)
            obj.rot_speed_degs = obj.rot_speed_field.Value;
            
            obj.rot_mm_per_rev = obj.rot_mm_rev_field.Value;
            obj.rot_pulses_per_rev = obj.rot_pulses_rev_field.Value;
        end
        
        function Configure(obj)
            % Configures the AMC4030 motion controller
            
            obj.Update();
            
            obj.configurationLamp.Color = "yellow";
            obj.textArea.Value = "";
            pause(0.1)
            
            obj.Update();
            
            if ~obj.isConnected || obj.EnsureConnection() ~= 1
                obj.textArea.Value = "Error: Connect AMC4030 Motion Controller before trying to configure!";
                obj.isConfigured = false;
                obj.configurationLamp.Color = "red";
                return;
            end
            
            if obj.UploadConfig_AMC4030() == -1
                obj.isConfigured = false;
                obj.configurationLamp.Color = "red";
                obj.textArea.Value = "Failed to configure AMC4030!";
                return;
            end
            
            obj.isConfigured = true;
            obj.configurationLamp.Color = "green";
            obj.textArea.Value = "Configured AMC4030 succesfully";
        end
        
        function err = SerialConnect(obj)
            % Connect the AMC4030 over serial
            %
            % Outputs
            %   1   :   Succesful Connection
            %   -1  :   Error in Connection
            
            % Load the AMC4030 Library
            if ~libisloaded('AMC4030')
                loadlibrary('AMC4030.dll', @ComInterfaceHeader);
            end
            
            % Prompt and choose serial port for AMC4030
            [obj.COMPortNum,~,tf] = serialSelect("Select: ""USB-SERIAL CH340""");
            
            if tf
                serialPortName = "COM" + obj.COMPortNum;
                
                % Establish the communication
                calllib('AMC4030','COM_API_SetComType',2);
                for ii = 1:3
                    err = calllib('AMC4030','COM_API_OpenLink',obj.COMPortNum,115200);
                    if libisloaded('AMC4030') && err == 1
                        obj.isConnected = true;
                        obj.connectionLamp.Color = 'green';
                        obj.textArea.Value = "Connected AMC4030 at " + serialPortName;
                        
                        if obj.isApp
                            figure(obj.app.UIFigure);
                        end
                        return;
                    end
                    obj.textArea.Value = ii + "th Connection Failure";
                end
                
                err = -1;
                obj.isConnected = false;
                obj.textArea.Value = "Unable to connect to " + serialPortName + " is another application connected?";
            else
                % No serial port selected
                obj.textArea.Value = "Invalid COM port selected or no COM port selected. Verify connection and try again.";
                
                if obj.isApp
                    figure(obj.app.UIFigure);
                end
                err = -1;
            end
        end
        
        function SingleCommand(obj,hor_move_mm,ver_move_mm,rot_move_deg)
            
            if ~obj.isConnected
                obj.textArea.Value = "ERROR: Connect motion controller before attempting single movement!";
                return;
            end
            
            if ~obj.isConfigured
                obj.textArea.Value = "ERROR: Configure motion controller before attempting single movement!";
                return;
            end
            
            obj.textArea.Value = "Sending single command";
            
            [err,wait_time_hor] = obj.Move_Horizontal(hor_move_mm);
            if err == -1
                obj.textArea.Value = "ERROR! Horizontal movement failed!!";
            end
            
            [err,wait_time_ver] = obj.Move_Vertical(ver_move_mm);
            if err == -1
                obj.textArea.Value = "ERROR! Vertical movement failed!!";
            end
            
            [err,wait_time_rot] = obj.Move_Rotational(rot_move_deg);
            if err == -1
                obj.textArea.Value = "ERROR! Rotational movement failed!!";
            end
            
            pause(max([wait_time_hor,wait_time_ver,wait_time_rot]));
            if err ~= -1
                obj.textArea.Value = "Completed single movement";
            end
        end
        
        function [err,wait_time] = Move_Horizontal(obj,hor_move_mm)
            % Outputs
            %   1   :   Successful Movement
            %   0   :   No Movement Required
            %   -1  :   Error in Movement
            
            wait_time = 0;
            
            if obj.curr_hor_mm + hor_move_mm > obj.hor_max_mm
                % Cannot exceed maximum
                err = 0;
                return;
            elseif obj.curr_hor_mm + hor_move_mm < 0
                % Cannot go to negative position
                err = 0;
                return;
            end
            
            % Do the movement using the AMC4030 Controller
            if hor_move_mm ~= 0
                for ii = 1:obj.patience
                    if 1 == obj.Move_AMC4030(0,hor_move_mm,obj.hor_speed_mms)
                        break;
                    else
                        obj.textArea.Value = ii + "th Horizontal Movement Failure";
                        if ii == obj.patience
                            obj.textArea.Value = "Horizontal Movement of " + hor_move_mm + " mm Failed!";
                            err = -1;
                            return;
                        end
                    end
                end
                
                obj.curr_hor_mm = obj.curr_hor_mm + hor_move_mm;
                obj.curr_hor_field.Value = obj.curr_hor_mm;
                err = 1;
                wait_time = abs(hor_move_mm/obj.hor_speed_mms) + obj.wait_tol*obj.hor_speed_mms;
                return;
            else
                err = 0;
                return;
            end
        end
        
        function [err,wait_time] = Move_Vertical(obj,ver_move_mm)
            % Outputs
            %   1   :   Successful Movement
            %   0   :   No Movement Required
            %   -1  :   Error in Movement
            
            wait_time = 0;
            
            if obj.curr_ver_mm + ver_move_mm > obj.ver_max_mm
                % Cannot exceed maximum
                err = 0;
                return;
            elseif obj.curr_ver_mm + ver_move_mm < 0
                % Cannot go to negative position
                err = 0;
                return;
            end
            
            % Do the movement using the AMC4030 Controller
            if ver_move_mm ~= 0
                for ii = 1:obj.patience
                    if 1 == obj.Move_AMC4030(1,ver_move_mm,obj.ver_speed_mms)
                        break;
                    else
                        obj.textArea.Value = ii + "th Vertical Movement Failure";
                        if ii == obj.patience
                            obj.textArea.Value = "Vertical Movement of " + ver_move_mm + " mm Failed!";
                            err = -1;
                            return;
                        end
                    end
                end
                
                obj.curr_ver_mm = obj.curr_ver_mm + ver_move_mm;
                obj.curr_ver_field.Value = obj.curr_ver_mm;
                err = 1;
                wait_time = abs(ver_move_mm/obj.ver_speed_mms) + obj.wait_tol*obj.ver_speed_mms;
                return;
            else
                err = 0;
                return;
            end
        end
        
        function [err,wait_time] = Move_Rotational(obj,rot_move_deg)
            % Outputs
            %   1   :   Successful Movement
            %   0   :   No Movement Required
            %   -1  :   Error in Movement
            
            wait_time = 0;
            
            % Do the movement using the AMC4030 Controller
            if rot_move_deg ~= 0
                for ii = 1:obj.patience
                    if 1 == obj.Move_AMC4030(2,rot_move_deg,obj.rot_speed_degs)
                        break;
                    else
                        obj.textArea.Value = ii + "th Rotational Movement Failure";
                        if ii == obj.patience
                            obj.textArea.Value = "Rotational Movement of " + rot_move_deg + " deg Failed!";
                            err = -1;
                            return;
                        end
                    end
                end
                
                obj.curr_rot_deg = obj.curr_rot_deg + rot_move_deg;
                obj.curr_rot_field.Value = obj.curr_rot_deg;
                err = 1;
                wait_time = abs(rot_move_deg/obj.rot_speed_degs) + obj.wait_tol*obj.rot_speed_degs;
                return;
            else
                err = 0;
                return;
            end
        end
        
        function err = Move_AMC4030(obj,axisNum,distance_mm,speed_mmps)
            if ~obj.isConnected || obj.EnsureConnection() ~= 1
                obj.textArea.Value = "AMC4030 Must Be Connected to Move!!";
                err = -1;
                return;
            end
            err = calllib('AMC4030','COM_API_Jog',axisNum,distance_mm,speed_mmps);
            % Example call to move 'x' axis to '30 mm' at '20 mm/s'
            % err = calllib('AMC4030','COM_API_Jog',0,30,20);
        end
        
        function err = Home_AMC4030(obj,isHor,isVer,isRot)
            if ~obj.isConnected || obj.EnsureConnection() ~= 1
                obj.textArea.Value = "AMC4030 Must Be Connected to Home!!";
                err = -1;
                return;
            end
            err = calllib('AMC4030','COM_API_Home',isHor,isVer,isRot);
            % Example call to move 'x' axis home
            % err = calllib('AMC4030','COM_API_Home',1,0,0);
            
            if err == 1
                if isHor
                    obj.curr_hor_mm = 0;
                end
                if isVer
                    obj.curr_ver_mm = 0;
                end
                if isRot
                    obj.curr_rot_deg = 0;
                end
            end
        end
        
        function err = Stop_AMC4030(obj,isHor,isVer,isRot)
            if ~obj.isConnected || obj.EnsureConnection() ~= 1
                obj.textArea.Value = "AMC4030 Must Be Connected to Stop!!";
                err = -1;
                return;
            end
            err = calllib('AMC4030','COM_API_StopAxis',isHor,isVer,isRot);
            % Example call to stop 'x' axis
            % err = calllib('AMC4030','COM_API_StopAxis',1,0,0);
        end
        
        function err = Stop_All(obj)
            if ~obj.isConnected || obj.EnsureConnection() ~= 1
                obj.textArea.Value = "AMC4030 Must Be Connected to Stop!!";
                err = -1;
                return
            end
            err = calllib('AMC4030','COM_API_StopAll');
            % Example call to stop all axes
            % err = calllib('AMC4030','COM_API_StopAll');
        end
        
        function err = EnsureConnection(obj)
            % Ensure that the AMC4030 is still connected
            %
            % Outputs
            %   1   :   AMC4030 is connected
            %   -1  :   AMC4030 is disconnected
            
            calllib('AMC4030','COM_API_SetComType',2);
            err = calllib('AMC4030','COM_API_OpenLink',obj.COMPortNum,115200);
            if err ~= 1
                obj.textArea.Value = "AMC4030 Disconnected!";
                obj.isConnected = false;
                obj.connectionLamp.Color = "red";
                err = -1;
                return;
            end
            
            obj.isConnected = true;
            obj.connectionLamp.Color = "green";
            err = 1;
        end
        
        function err = UploadConfig_AMC4030(obj)
            % Uploads the configuration to the AMC4030 from the file
            %
            % Outputs
            %   1   :   Successfully uploaded configuration
            %   -1  :   Could not upload configuration;
            
            if obj.CreateConfigFile() == -1
                obj.isConfigured = false;
                err = -1;
                return;
            end
            
            if calllib('AMC4030','COM_API_DowloadSystemCfg',char(obj.configFilePath)) ~= 1
                obj.textArea.Value = "Error uploading AMC4030 configuration file to device!";
                obj.isConfigured = false;
                err = -1;
                return;
            end
            
            err = 1;
        end
        
        function err = CreateConfigFile(obj)
            % Creates the config file
            %
            % Outputs
            %   1   :   Successfully created config file
            %   -1  :   Could not create config file successfully
            
            obj.CreateConfigString();
            
            fid = fopen(obj.configFilePath,"wt");
            
            if fid == -1
                obj.textArea.Value = "Error opening AMC4030 config file at " + obj.configFilePath;
                err = -1;
                return;
            end
            
            % Print the config string to the file
            fprintf(fid,'%s\n',obj.configString);
            
            fclose(fid);
            obj.textArea.Value = "Created AMC4030 configuration file successfully at " + obj.configFilePath;
            err = 1;
        end
        
        function CreateConfigString(obj)
            % Creates the string array holding the lines of the
            % configuration file
            
            obj.configString = [
                "[Head]"
                "MachineType=4030"
                "Version=1000"
                ""
                "[MachineParam]"
                "fTimerPeriod=1"
                "fWorkPrecision=0.001"
                "fArcCheckPrecision=0.01"
                "fMinLen=0.02"
                "fMaxFeedSpeed=150000"
                "nAccelType=0"
                "wHomePowerOn=0"
                "fMaxAccelSpeed=20000"
                "fAccelSpeed=200"
                "fFastAccelSpeed=1000"
                "fJAccelSpeed=10000"
                "nHomePowerOn=0"
                ""
                "[XAxisParam]"
                "nPulseFactorUp=" + obj.hor_pulses_per_rev
                "nPulseFactorDown=" + obj.hor_mm_per_rev
                "nPulseLogic=0"
                "fMaxSpeed=333"
                "fMaxPos=" + obj.hor_max_mm
                "nEnableBacklash=0"
                "fBacklashLen=0"
                "fBacklashSpeed=0"
                "nHomeDir=-1"
                "fHomeSpeed=" + obj.hor_speed_home_mms
                "fHomeCheckDis=50"
                "fHomeZeroSpeed=10"
                "fHomeOrgSpeed=5"
                "fHomePosOffset=" + obj.hor_home_offset_mm
                ""
                "[YAxisParam]"
                "nPulseFactorUp=" + obj.ver_pulses_per_rev
                "nPulseFactorDown=" + obj.ver_mm_per_rev
                "nPulseLogic=0"
                "fMaxSpeed=333"
                "fMaxPos=" + obj.ver_max_mm
                "nEnableBacklash=0"
                "fBacklashLen=0"
                "fBacklashSpeed=0"
                "nHomeDir=-1"
                "fHomeSpeed=" + obj.ver_speed_home_mms
                "fHomeCheckDis=50"
                "fHomeZeroSpeed=10"
                "fHomeOrgSpeed=5"
                "fHomePosOffset=" + obj.ver_home_offset_mm
                ""
                "[ZAxisParam]"
                "nPulseFactorUp=25000"
                "nPulseFactorDown=36"
                "nPulseLogic=0"
                "fMaxSpeed=333"
                "fMaxPos=200"
                "nEnableBacklash=0"
                "fBacklashLen=0"
                "fBacklashSpeed=0"
                "nHomeDir=-1"
                "fHomeSpeed=20"
                "fHomeCheckDis=50"
                "fHomeZeroSpeed=10"
                "fHomeOrgSpeed=5"
                "fHomePosOffset=5"];
        end
    end
end