classdef ESP32_Device < handle
    properties
        isConnected = false     % Boolean whether or not the ESP32 is connected
        isConfigured = false    % Boolean whether or not the ESP32 is configured
        COMPortNum              % COM Port number of the ESP32
        
        connectionLamp          % Lamp in the GUI for the ESP32 connection
        configurationLamp       % Lamp in the GUI for the ESP32 configuration
        textArea                % Text area in the GUI for showing statuses
    end
    methods
        function obj = ESP32_Device(app)
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % ATTENTION Ben: LOOK FOR "TODO" statements where you will make
            % changes and add code
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if ~isempty(app)
                obj.textArea = app.MainTextArea;
            end
        end
        
        function obj = SerialConnect(obj,app)
            % Prompt and choose serial port for ESP32
            serialList = serialportlist;
            [serialIdx,tf] = listdlg('PromptString','Select ESP32 Port:','SelectionMode','single','ListString',serialList);
            
            if tf
                serialPortNumber = sscanf(serialList(serialIdx),"COM%d",1);
                serialPortName = append("COM",num2str(serialPortNumber));
                obj.COMPortNum = serialPortNumber;
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % TODO: write procedure for connecting to the ESP32
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                warning("TODO: NOT YET IMPLEMENTED")
                
                obj.isConnected = true;
                obj.connectionLamp.Color = 'green';
            else
                % No serial port selected
                obj.textArea.Value = "Invalid COM port selected or no COM port selected. Verify connection and try again.";
                disp(obj.textArea.Value)
            end
            
            if ~isempty(app)
                figure(app.UIFigure);
            end
        end
        
        function obj = SerialDisconnect(obj)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % TODO: write procedure for disconnection from the ESP32
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            obj.isConnected = false;
            obj.connectionLamp.Color = 'red';
        end
        
        function obj = Configure(obj)
            obj.configurationLamp = 'yellow';
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % TODO: write procedure for configuring the MCU. This is where
            % you will send the commands to the ESP32 and make sure to get
            % back the acknowledgement. After being configured, the ESP32
            % will be waiting for the pulses from the stepper driver. See
            % Fig. 7 of Muhammet's testbed paper
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            obj.isConfigured = true;
            obj.configurationLamp = 'green';
        end
    end
end