classdef Drawer_Device < handle
    properties
        isConnected = false     % Boolean whether or not the drawer is connected
        isConfigured = false    % Boolean whether or not the drawer is configured
        COMPort                 % COM port number of the drawer
        
        connectionLamp          % Lamp in the GUI for the drawer connection
        configurationLamp       % Lamp in the GUI for the drawer configuration
        textArea                % Text area in the GUI for showing statuses
        
        hor_speed_mms = 20      % Speed of horizontal movement in mm/s
        ver_speed_mms = 20      % Speed of vertical movement in mm/s
        rot_speed_degs = 20     % Speed of rotational movement in deg/s
        
        hor_speed_max_mms = 50  % Speed of horizontal movement in mm/s
        ver_speed_max_mms = 50  % Speed of vertical movement in mm/s
        rot_speed_max_degs = 50 % Speed of rotational movement in deg/s
        
        curr_hor_mm = 0         % Current horizontal position
        curr_ver_mm = 0         % Current vertical position
        curr_rot_deg = 0        % Current rotational position
    end
    
    methods
        function obj = Drawer_Device(app)
            % Note:
            % Horizontal    : X-Axis on drawer
            % Veritcal      : Y-Axis on drawer
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % ATTENTION YUSEF: LOOK FOR "TODO" statements where you will
            % make changes and add code
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if ~isempty(app)
                obj.textArea = app.MainTextArea;
            end
        end
        
        function err = SerialConnect(obj)
            % Outputs
            %   1   :   Succesful Connection
            %   -1  :   Error in Connection
            
            % Prompt and choose serial port for drawer
            serialList = serialportlist;
            [serialIdx,tf] = listdlg('PromptString','Select Drawer Port:','SelectionMode','single','ListString',serialList);
            
            if tf
                serialPortNumber = sscanf(serialList(serialIdx),"COM%d",1);
                serialPortName = append("COM",num2str(serialPortNumber));
                obj.COMPort = serialPortNumber;
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % TODO: write procedure for connecting to the drawer here
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
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
            
            if hor_move_mm ~= 0
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % TODO: write procedure for moving +/- in the horizontal
                % direction
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
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
            
            if ver_move_mm ~= 0
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % TODO: write procedure for moving +/- in the vertical
                % direction
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                obj.curr_ver_mm = obj.curr_ver_mm + ver_move_mm;
                err = 1;
                wait_time = abs(ver_move_mm/obj.ver_speed_mms);
                return;
            else
                err = 0;
                return;
            end
        end
        
        function err = Stop_All(obj)
            % Outputs
            %   1   :   Successfully Stopped Both Axes
            %   0   :   No Stop Required: Already Stopped
            %   -1  :   Error in Stopping Axes
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % TODO: write procedure stopping the movement mid-motion, if
            % possible
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
    end
end