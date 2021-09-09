classdef ESP32_Device < handle
    properties
        isConnected = false     % Boolean whether or not the ESP32 is connected
        isConfigured = false    % Boolean whether or not the ESP32 is configured
        COMPortNum              % COM Port number of the ESP32
        serialDevice            % MATLAB serialport object
        baudRate = 115200       % Baud rate for connection with ESP32
        serialPatience = 5      % Number of times to check the serial for an appropriate send back from the ESP32 in the form "drs X"
        
        mm_per_rev              % Number of millimeters per revolution
        pulses_per_rev          % Number of pulses per revolution
        xStep_mm                % Step size in the x-direction in mm
        xOffset_mm              % Offset in the x-direction in mm
        DeltaX_mm               % Separation between radars in the x-direction in mm
        numX                    % Number of steps in the x-direction
        numY                    % Number of steps in the y-direction
        radarSelect             % Radar selection (1 = radar 1 only, 2 = radar 2 only, 3 = radar 1 and radar 2)
        
        connectionLamp          % Lamp in the GUI for the ESP32 connection
        configurationLamp       % Lamp in the GUI for the ESP32 configuration
        textArea                % Text area in the GUI for showing statuses
    end
    methods
        function obj = ESP32_Device(app)
            if ~isempty(app)
                obj.textArea = app.MainTextArea;
            end
        end
        
        function err = SerialConnect(obj,app)
            % Connect to the ESP32 over serial
            %
            % Outputs
            %   1   :   Successfully connected to serial
            %   -1  :   Failed to connect over serial
            
            % Prompt and choose serial port for ESP32
            serialList = serialportlist;
            [serialIdx,tf] = listdlg('PromptString','Select ESP32 Port:','SelectionMode','single','ListString',serialList);
            
            if tf
                serialPortNumber = sscanf(serialList(serialIdx),"COM%d",1);
                serialPortName = "COM" + serialPortNumber;
                obj.COMPortNum = serialPortNumber;
                
                % Create connection to serial port
                obj.serialDevice = serialport(serialPortName,obj.baudRate);
                
                % Configure terminator
                configureTerminator(obj.serialDevice,"LF");
                
                obj.isConnected = true;
                obj.connectionLamp.Color = 'green';
                obj.textArea.Value = "Successfully connected ESP32 at COM" + obj.COMPortNum;
                
                if ~isempty(app)
                    figure(app.UIFigure);
                end
                err = 1;
            else
                % No serial port selected
                obj.textArea.Value = "Invalid COM port selected or no COM port selected. Verify connection and try again.";
                obj.SerialDisconnect();
                
                if ~isempty(app)
                    figure(app.UIFigure);
                end
                err = -1;
            end
        end
        
        function obj = SerialDisconnect(obj)
            % Disconnect from the ESP32 over serial
            
            % Clear the serialport object
            obj.serialDevice = [];
            obj.COMPortNum = 0;
            
            obj.isConnected = false;
            obj.connectionLamp.Color = 'red';
        end
        
        function err = SendStart(obj)
            % Will start the ESP32 listening for pulses
            %
            % Outputs
            %   1   :   Successfully started listening for pulses
            %   -1  :   Error starting ESP32 to listen for pulses
            
            if ~obj.isConnected
                obj.configurationLamp = 'red';
                obj.textArea.Value = "ESP32 is not connected! Must connect ESP32 before starting scan.";
            end
            
            str = "sarStart " +...
                obj.mm_per_rev + " " +...
                obj.pulses_per_rev + " " +...
                obj.xStep_mm + " " +...
                obj.xOffset_mm + " " +...
                obj.numX + " " +...
                obj.numY + " " +...
                obj.radarSelect + " "+...
                obj.DeltaX_mm + " ";
            
            [sendErr,sendRet] = obj.SendSerial(str,1);
            
            if sendErr == 1
                err = 1;
                obj.textArea.Value = "ESP32 started successfully with " + obj.RadarNumStr();
                pause(0.5);
            elseif sendRet == -2
                err = -1;
                obj.textArea.Value = "Error starting ESP32! Scan already in progress on ESP32!";
                pause(0.5);
            else
                err = -1;
                obj.textArea.Value = "Error starting ESP32! May need to power cycle ESP32!";
                pause(0.5);
            end
        end
        
        function err = SendStop(obj)
            % Send the sarStop emergency stop command over serial and
            % verify the return value sent back from the ESP32
            %
            % Outputs
            %   1   :   Successfully sent emergency stop
            %   -1  :   Failed emergency stop
            
            if obj.SendSerial("sarStop",-1) == 1
                err = 1;
            else
                err = -1;
            end
        end
        
        function err = SendNextUp(obj)
            % Send the sarNextUp command over serial and verify the return
            % value sent back from the ESP32
            %
            % Outputs
            %   1   :   Successfully sent sarNext command to ESP32
            %   -1  :   Error in sending sarNext command to ESP32
            
            if obj.SendSerial("sarNextUp",4) == 1
                err = 1;
            else
                err = -1;
            end
        end
        
        function err = SendNextDown(obj)
            % Send the sarNextUp command over serial and verify the return
            % value sent back from the ESP32
            %
            % Outputs
            %   1   :   Successfully sent sarNext command to ESP32
            %   -1  :   Error in sending sarNext command to ESP32
            
            if obj.SendSerial("sarNextDown",6) == 1
                err = 1;
            else
                err = -1;
            end
        end
        
        function [err,retVal] = SendSerial(obj,sendVal,expectedRetVal)
            % Send a command to the ESP over serial and check the return
            % value sent back from the ESP32
            %
            % Outputs
            %   1       :   Successful communication with ESP32
            %   -1      :   Error in communication with ESP32
            %   -1000   :   Fatal error in ESP32 - stopping scan
            
            if ~obj.isConnected
                obj.textArea.Value = "Error sending: ESP32 is not connected! Please connect before trying to send any commands";
                err = -1;
                return;
            end
            
            % Flush the serial device
            flush(obj.serialDevice);
            
            % Write the data to the serialport
            writeline(obj.serialDevice,sendVal);
            
            % Read the response
            retVal = obj.ReadSerial_drs();
            
            % Confirm the response
            if ~isempty(retVal) && retVal == expectedRetVal
                err = 1;
            elseif ~isempty(retVal) && retVal == -1000
                err = -1000;
                obj.textArea.Value = "ESP32 encountered fatal error!!";
                pause(0.5);
            else
                err = -1;
            end
        end
        
        function s = ReadSerial_drs(obj)
            % Read the serial return from the ESP32 in the format specified
            % below
            %
            % Outputs
            %   s   :   Return value from ESP32 in the form "drs X", where
            %   X is the return value
            %   []  :   No valid return value was read
            
            % Look through serialPatience number of times, may cause a
            % longer execution time if serialPatience is large
            
            ii = obj.serialPatience;
            
            while ii > 0
                serialLine = readline(obj.serialDevice);
                if ~isempty(serialLine)
                    s = sscanf(serialLine,"drs %d");
                else
                    s = [];
                    return;
                end
                if isstring(s) && contains(s,"drs_debug ")
                    obj.textArea.Value = extractAfter(s,"drs_debug ");
                    continue;
                end
                if ~isempty(s)
                    break
                end
                ii = ii - 1;
            end
        end
        
        function err = CheckUpDone(obj)
            % Checks if the ESP32 has sent the correct number of triggers
            % in the upward direction 
            %
            % Outputs
            %   1       :   ESP32 is done with horizontal scan
            %   -1      :   ESP32 is not done with horizontal scan
            %   -1000   :   Fatal error in ESP32 - stopping scan
            
            retVal = obj.ReadSerial_drs();
            
            % Confirm the response
            if ~isempty(retVal) && retVal == 3
                err = 1;
                obj.textArea.Value = "ESP32 done with horizontal scan succesfully";
            elseif ~isempty(retVal) && retVal == -1000
                err = -1000;
                obj.textArea.Value = "ESP32 encountered fatal error!!";
                pause(0.5);
            else
                err = -1;
                obj.textArea.Value = "No horizontal scan confirmation received!";
                pause(0.5);
            end
        end
        
        function err = CheckDownDone(obj)
            % Checks if the ESP32 has sent the correct number of triggers
            % in the upward direction 
            %
            % Outputs
            %   1       :   ESP32 is done with horizontal scan
            %   -1      :   ESP32 is not done with horizontal scan
            %   -1000   :   Fatal error in ESP32 - stopping scan
            
            retVal = obj.ReadSerial_drs();
            
            % Confirm the response
            if ~isempty(retVal) && retVal == 5
                err = 1;
                obj.textArea.Value = "ESP32 done with horizontal scan succesfully";
            elseif ~isempty(retVal) && retVal == -1000
                err = -1000;
                obj.textArea.Value = "ESP32 encountered fatal error!!";
                pause(0.5);
            else
                err = -1;
                obj.textArea.Value = "No horizontal scan confirmation received!";
                pause(0.5);
            end
        end
        
        function err = CheckScanDone(obj)
            % Checks if the ESP32 has completed the entire SAR scan
            %
            % Outputs
            %   1       :   ESP32 is done with scan
            %   -1      :   ESP32 is not done with scan
            %   -1000   :   Fatal error in ESP32 - stopping scan
            
            retVal = obj.ReadSerial_drs();
            
            % Confirm the response
            if ~isempty(retVal) && retVal == 2
                err = 1;
                obj.textArea.Value = "ESP32 done with scan succesfully";
            elseif ~isempty(retVal) && retVal == -1000
                err = -1000;
                obj.textArea.Value = "ESP32 encountered fatal error!!";
                pause(0.5);
            else
                err = -1;
                obj.textArea.Value = "No scan completion confirmation received";
                pause(0.5);
            end
        end
        
        function err = CheckError(obj)
            % TODO: how can we check on this error?? 
            
            % Checks if the ESP32 has encountered an error
            %
            % Outputs
            %   1       :   ESP32 has not encountered an error
            %   -1      :   ESP32 has encountered an error
            %   -1000   :   Fatal error in ESP32 - stopping scan
            
            retVal = obj.ReadSerial_drs();
            
            % Confirm the response
            if ~isempty(retVal) && retVal == 2
                err = 1;
                obj.textArea.Value = "ESP32 done with scan succesfully";
            elseif ~isempty(retVal) && retVal == -1000
                err = -1000;
                obj.textArea.Value = "ESP32 encountered fatal error!!";
                pause(0.5);
            else
                err = -1;
                obj.textArea.Value = "No scan completion confirmation received";
                pause(0.5);
            end
        end
        
        function str = RadarNumStr(obj)
            % Returns the string with the number of radars
            if obj.radarSelect == 1
                str = "radar 1 only";
            elseif obj.radarSelect == 2
                str = "radar 2 only";
            elseif obj.radarSelect == 3
                str = "dual radars";
            end
        end
    end
end