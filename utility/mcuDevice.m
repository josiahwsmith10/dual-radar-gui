classdef mcuDevice
    properties
        isConnected
        isConfigured
        COMPort
        COMPortNum
        
        connectionLamp
        configurationLamp
        textArea
    end
    methods
        function obj = mcuDevice(app)
            obj.textArea = app.MainTextArea;
            
            obj.isConnected = false;
            obj.isConfigured = false;
            obj.COMPort = 0;
        end
        
        function obj = serialConnectMCU(obj)
            % Prompt and choose serial port for MCU
            serialList = serialportlist;
            [serialIdx,tf] = listdlg('PromptString','Select Microcontroller Port:','SelectionMode','single','ListString',serialList);
            
            if tf
                serialPortNumber = sscanf(serialList(serialIdx),"COM%d",1);
                serialPortName = append("COM",num2str(serialPortNumber));
                obj.COMPortNum = serialPortNumber;
                try
                    obj.COMPort = serialport(serialPortName,app.MCU_Baudrate);
                    fprintf('MCU Connected on %s.\n',serialPortName);
                    configureTerminator(obj.COMPort,"CR");
                    obj.isConnected = true;
                    
                    pause(0.01)
                    obj.connectionLamp.Color = 'green';
                catch
                    obj.textArea.Value = "Unable to connect to " +  serialPortName + " is another application connected?";
                end
            else
                % No serial port selected
                obj.textArea.Value = "Invalid COM port selected or no COM port selected. Verify connection and try again.";
            end
        end
    end
    
    
end