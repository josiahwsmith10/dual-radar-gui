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
        
        curr_hor_mm = 0         % Current horizontal position
        curr_ver_mm = 0         % Current vertical position
        curr_rot_deg = 0        % Current rotational position
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
        end
        
        function err = SerialConnect(obj,app)
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
                serialPortName = append("COM",num2str(serialPortNumber));
                obj.COMPort = serialPortNumber;
                
                % Establish the communication
                calllib('AMC4030','COM_API_SetComType',2);
                for ii = 1:3
                    err = calllib('AMC4030','COM_API_OpenLink',obj.COMPort,115200);
                    if libisloaded('AMC4030') && err == 1
                        obj.isConnected = true;
                        obj.connectionLamp.Color = 'green';
                        
                        if ~isempty(app)
                            figure(app.UIFigure);
                        end
                        return;
                    end
                    obj.textArea.Value = ii + "th Connection Failure";
                    disp(obj.textArea.Value)
                end
                
                err = -1;
                obj.isConnected = false;
                obj.textArea.Value = "Unable to connect to " + serialPortName + " is another application connected?";
                disp(obj.textArea.Value)
            else
                % No serial port selected
                obj.textArea.Value = "Invalid COM port selected or no COM port selected. Verify connection and try again.";
                disp(obj.textArea.Value)
            end
        end
        
        function [err,wait_time] = Move_Horizontal(obj,hor_move_mm)
            % Outputs
            %   1   :   Successful Movement
            %   0   :   No Movement Required
            %   -1  :   Error in Movement
            
            wait_time = 0;
            
            % Do the movement using the AMC4030 Controller
            if hor_move_mm ~= 0
                for ii = 1:obj.patience
                    if 1 == obj.Move_AMC4030(0,hor_move_mm,obj.hor_speed_mms)
                        break;
                    else
                        obj.textArea.Value = ii + "th Horizontal Movement Failure";
                        disp(obj.textArea.Value)
                        if ii == obj.patience
                            obj.textArea.Value = "Horizontal Movement of " + hor_move_mm + " mm Failed!";
                            disp(obj.textArea.Value)
                            err = -1;
                            return;
                        end
                    end
                end
                
                obj.curr_hor_mm = obj.curr_hor_mm + hor_move_mm;
                err = 1;
                wait_time = abs(hor_move_mm/obj.hor_speed_mms);
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
            
            % Do the movement using the AMC4030 Controller
            if ver_move_mm ~= 0
                for ii = 1:obj.patience
                    if 1 == obj.Move_AMC4030(1,ver_move_mm,obj.ver_speed_mms)
                        break;
                    else
                        obj.textArea.Value = ii + "th Vertical Movement Failure";
                        disp(obj.textArea.Value)
                        if ii == obj.patience
                            obj.textArea.Value = "Vertical Movement of " + ver_move_mm + " mm Failed!";
                            disp(obj.textArea.Value)
                            err = -1;
                            return;
                        end
                    end
                end
                
                obj.curr_ver_mm = obj.curr_ver_mm + ver_move_mm;
                err = 1;
                wait_time = abs(ver_move_mm/obj.ver_speed_mms);
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
                        disp(obj.textArea.Value)
                        if ii == obj.patience
                            obj.textArea.Value = "Rotational Movement of " + rot_move_deg + " deg Failed!";
                            disp(obj.textArea.Value)
                            err = -1;
                            return;
                        end
                    end
                end
                
                obj.curr_rot_deg = obj.curr_rot_deg + rot_move_deg;
                err = 1;
                wait_time = abs(rot_move_deg/obj.rot_speed_degs);
                return;
            else
                err = 0;
                return;
            end
        end
        
        function err = Move_AMC4030(obj,axisNum,distance_mm,speed_mmps)
            if ~obj.isConnected
                error("AMC4030 Must Be Connected to Move!!")
            end
            err = calllib('AMC4030','COM_API_Jog',axisNum,distance_mm,speed_mmps);
            % Example call to move 'x' axis to '30 mm' at '20 mm/s'
            % err = calllib('AMC4030','COM_API_Jog',0,30,20);
        end
        
        function err = Home_AMC4030(obj,isHor,isVer,isRot)
            if ~obj.isConnected
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
            if ~obj.isConnected
                error("AMC4030 Must Be Connected to Stop!!")
            end
            err = calllib('AMC4030','COM_API_StopAxis',isHor,isVer,isRot);
            % Example call to stop 'x' axis
            % err = calllib('AMC4030','COM_API_StopAxis',1,0,0);
        end
        
        function err = Stop_All(obj)
            if ~obj.isConnected
                error("AMC4030 Must Be Connected to Stop!!")
            end
            err = calllib('AMC4030','COM_API_StopAll');
            % Example call to stop all axes
            % err = calllib('AMC4030','COM_API_StopAll');
        end
    end
    
    methods(Static)
    end
end