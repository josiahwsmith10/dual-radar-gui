classdef AMC4030_Device < handle
    properties
        isConnected = false     % Boolean whether or not the AMC4030 device is connected
        isConfigured = false    % Boolean whether or not the AMC4030 device is configured
        COMPort                 % COM port number of the AMC4030
        
        connectionLamp          % Lamp in the GUI for the AMC4030 connection
        configurationLamp       % Lamp in the GUI for the AMC4030 configuration
        textArea                % Text area in the GUI for showing statuses
        
        patience = 10           % Number of attempts for movement in any direction before giving up, default = 10
        
        hor_speed_mms = 20      % Speed of horizontal movement in mm/s
        ver_speed_mms = 20      % Speed of vertical movement in mm/s
        rot_speed_degs = 20     % Speed of rotational movement in deg/s
        
        hor_speed_max_mms = 50  % Maximum speed of horizontal movement in mm/s
        ver_speed_max_mms = 50  % Maximum speed of vertical movement in mm/s
        rot_speed_max_degs = 50 % Speed of rotational movement in deg/s
        
        hor_speed_home_mms = 20 % Homing speed of horizontal movement in mm/s
        ver_speed_home_mms = 20 % Homing speed of horizontal movement in mm/s
        
        curr_hor_mm = 0         % Current horizontal position
        curr_ver_mm = 0         % Current vertical position
        curr_rot_deg = 0        % Current rotational position
        
        hor_max_mm = 500        % Maximum possible horizontal position in mm
        ver_max_mm = 500        % Maximum possible vertical position in mm
        
        mm_per_rev              % Number of millimeters per revolution
        pulses_per_rev          % Number of pulses per revolution
        
        configString            % String array holding every line of the
        configFilePath          % Path of the config file
    end
    
    methods
        function obj = AMC4030_Device(app)
            % Note:
            % Horizontal    : X-Axis on AMC4030
            % Veritcal      : Y-Axis on AMC4030
            % Rotational    : Z-Axis on AMC4030
            
            if ~isempty(app)
                obj.textArea = app.MainTextArea;
            end
            
            obj.configFilePath = cd + "\include\drsAMC4030Config.ini";
        end
        
        function obj = Configure(obj)
            % Configures the AMC4030 motion controller
            
            obj.configurationLamp.Color = "yellow";
            
            if ~obj.isConnected || obj.EnsureConnection() ~= 1
                obj.textArea.Value = "Error: Connect AMC4030 Motion Controller before trying to configure!";
                obj.isConfigured = false;
                obj.configurationLamp.Color = "red";
                return;
            end
            
            if obj.UploadConfig_AMC4030() == -1
                obj.isConfigured = false;
                obj.configurationLamp.Color = "red";
                return;
            end
            
            obj.isConfigured = true;
            obj.configurationLamp.Color = "green";
            obj.textArea.Value = "Configured AMC4030 succesfully";
        end
        
        function err = SerialConnect(obj,app)
            % Connect the AMC4030 over serial
            %
            % Outputs
            %   1   :   Succesful Connection
            %   -1  :   Error in Connection
            
            % Load the AMC4030 Library
            if ~libisloaded('AMC4030')
                loadlibrary('AMC4030.dll', @ComInterfaceHeader);
            end
            
            % Prompt and choose serial port for SAR scanner
            serialList = serialportlist;
            [serialIdx,tf] = listdlg('PromptString',"Select: ""USB-SERIAL CH340""",'SelectionMode','single','ListString',serialList);
            
            if tf
                serialPortNumber = sscanf(serialList(serialIdx),"COM%d",1);
                serialPortName = "COM" + serialPortNumber; 
                obj.COMPort = serialPortNumber;
                
                % Establish the communication
                calllib('AMC4030','COM_API_SetComType',2);
                for ii = 1:3
                    err = calllib('AMC4030','COM_API_OpenLink',obj.COMPort,115200);
                    if libisloaded('AMC4030') && err == 1
                        obj.isConnected = true;
                        obj.connectionLamp.Color = 'green';
                        obj.textArea.Value = "Connected AMC4030 at " + serialPortName;
                        
                        if ~isempty(app)
                            figure(app.UIFigure);
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
                
                if ~isempty(app)
                    figure(app.UIFigure);
                end
                err = -1;
            end
        end
        
        function [err,wait_time] = Move_Horizontal(obj,hor_move_mm,hor_field)
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
                hor_field.Value = obj.curr_hor_mm;
                err = 1;
                wait_time = abs(hor_move_mm/obj.hor_speed_mms);
                return;
            else
                err = 0;
                return;
            end
        end
        
        function [err,wait_time] = Move_Vertical(obj,ver_move_mm,ver_field)
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
                ver_field.Value = obj.curr_ver_mm;
                err = 1;
                wait_time = abs(ver_move_mm/obj.ver_speed_mms);
                return;
            else
                err = 0;
                return;
            end
        end
        
        function [err,wait_time] = Move_Rotational(obj,rot_move_deg,rot_field)
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
                rot_field.Value = obj.curr_rot_deg;
                err = 1;
                wait_time = abs(rot_move_deg/obj.rot_speed_degs);
                return;
            else
                err = 0;
                return;
            end
        end
        
        function err = Move_AMC4030(obj,axisNum,distance_mm,speed_mmps)
            if ~obj.isConnected || obj.EnsureConnection() ~= 1
                error("AMC4030 Must Be Connected to Move!!")
            end
            err = calllib('AMC4030','COM_API_Jog',axisNum,distance_mm,speed_mmps);
            % Example call to move 'x' axis to '30 mm' at '20 mm/s'
            % err = calllib('AMC4030','COM_API_Jog',0,30,20);
        end
        
        function err = Home_AMC4030(obj,isHor,isVer,isRot)
            if ~obj.isConnected || obj.EnsureConnection() ~= 1
                error("AMC4030 Must Be Connected to Home!!")
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
                error("AMC4030 Must Be Connected to Stop!!")
            end
            err = calllib('AMC4030','COM_API_StopAxis',isHor,isVer,isRot);
            % Example call to stop 'x' axis
            % err = calllib('AMC4030','COM_API_StopAxis',1,0,0);
        end
        
        function err = Stop_All(obj)
            if ~obj.isConnected || obj.EnsureConnection() ~= 1
                error("AMC4030 Must Be Connected to Stop!!")
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
            err = calllib('AMC4030','COM_API_OpenLink',obj.COMPort,115200);
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
            
            % Print every line of the config string to the file
            for subString = obj.configString
                fprintf(fid,'%s\n',subString);
            end
            
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
                "nPulseFactorUp=" + obj.pulses_per_rev
                "nPulseFactorDown=" + obj.mm_per_rev
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
                "fHomePosOffset=0"
                ""
                "[YAxisParam]"
                "nPulseFactorUp=" + obj.pulses_per_rev
                "nPulseFactorDown=" + obj.mm_per_rev
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
                "fHomePosOffset=0"
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
    
    methods(Static)
    end
end