classdef radarDevice
    properties (Access = public)
        num
        
        cliCommands
        
        isConnected
        isConfigured
        COMPort
        COMPortNum
        
        connectionLamp
        configurationLamp
        textArea
        
        f0_GHz
        K
        idleTime_us
        txStartTime_us
        adcStartTime_us
        adcSamples
        fS_ksps
        rampEndTime_us
        numFrames
        numChirps
        pri_ms
        nRx
        nTx
    end
    
    methods
        function obj = radarDevice(app,num)
            obj.num = num;
            obj.textArea = app.MainTextArea;
            
            obj.isConnected = false;
            obj.isConfigured = false;
            obj.COMPort = 0;
        end
        
        function obj = serialConnect(obj,app)
            % Prompt and choose serial port for radar
            serialList = serialportlist;
            [serialIdx,tf] = listdlg('PromptString','XDS110 Class Application/User UART port:','SelectionMode','single','ListString',serialList);
            
            if tf
                serialPortNumber = sscanf(serialList(serialIdx),"COM%d",1);
                serialPortName = append("COM",num2str(serialPortNumber));
                obj.COMPortNum = serialPortNumber;
                try
                    obj.COMPort = serialport(serialPortName,115200);
                    obj.textArea.Value = "Radar " + obj.num + " is connected on " + serialPortName;
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
            
            figure(app.UIFigure)
        end
        
        function obj = configureSensor(obj)
            if ~obj.isConnected
                obj.textArea.Value = "Connect radar before configuring";
                return;
            end
            
            obj = createCLICommands(obj);
            
            % Can we move this line here???
            % obj = writeCLICommands(obj);
            
            obj.configurationLamp.Color = "green";
        end
        
        function obj = startSensor(obj)
            if ~obj.isConnected || ~obj.isConfigured
                obj.textArea.Value = "Connect and configure radar before starting";
                return;
            end
            
            % Can we move this line up above???
            obj = writeCLICommands(obj);
            
            % Start the sensor
            try
                writeline(obj.COMPort,"sensorStart");
            catch
                obj.textArea.Value = "SERIAL CONNECTION TO RADAR " + obj.num + " LOST!";
                obj.isConnected = false;
                obj.connectionLamp.Color = red;
            end
        end
        
        function obj = writeCLICommands(obj)
            % Write CLI commands
            try
                for indCLI = 1:length(obj.cliCommands)
                    writeline(obj.COMPort,obj.cliCommands(indCLI));
                    % Very important pause
                    pause(0.05);
                end
            catch
                try
                    writeline(obj.COMPort,"sensorStop");
                catch
                    obj.textArea.Value = "SERIAL CONNECTION TO RADAR " + obj.num + " LOST!";
                    obj.isConnected = false;
                    obj.connectionLamp.Color = red;
                    return;
                end
                obj.textArea.Value = "Unable to read radar " + obj.num + " configuration file. Check for errors";
                return;
            end
        end
        
        function obj = createCLICommands(obj)
            % Create CLI command string array for 60 GHz radar IWR6843ISK
            if obj.num == 1
                obj.cliCommands = [
                    "sensorStop"
                    "flushCfg"
                    "dfeDataOutputMode 1"
                    "channelCfg 15 5 0"
                    "adcCfg 2 1"
                    "adcbufCfg -1 0 1 1 1"
                    %"profileCfg 0 60 7 3 24 0 0 166 1 256 12500 0 0 30"
                    "profileCfg 0 " + obj.f0_GHz + " " + obj.idleTime_us + " " + obj.adcStartTime_us + " " + obj.rampEndTime_us + ...
                    " 0 0 " + obj.K + " " + obj.txStartTime_us + " " + obj.adcSamples + " " + obj.fS_ksps + " 0 0 30"
                    "chirpCfg 0 0 0 0 0 0 0 1"
                    "chirpCfg 1 1 0 0 0 0 0 4"
                    %"frameCfg 0 1 1 0 100 1 0"
                    "frameCfg 0 1 " + obj.numChirps + " " + obj.numFrames + " " + obj.pri_ms + " 2 0" % the 2 at the end refers the hardware vs software trigger may need to change
                    "lowPower 0 0"
                    "guiMonitor -1 1 1 1 0 0 1"
                    "cfarCfg -1 0 2 8 4 3 0 15.0 0"
                    "cfarCfg -1 1 0 4 2 3 1 15.0 0"
                    "multiObjBeamForming -1 1 0.5"
                    "clutterRemoval -1 0"
                    "calibDcRangeSig -1 0 -5 8 256"
                    "compRangeBiasAndRxChanPhase 0.0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0"
                    "measureRangeBiasAndRxChanPhase 0 1. 0.2"
                    "aoaFovCfg -1 -90 90 -90 90"
                    "cfarFovCfg -1 0 0.25 9.0"
                    "cfarFovCfg -1 1 -20.16 20.16"
                    "extendedMaxVelocity -1 0"
                    "CQRxSatMonitor 0 3 4 63 0"
                    "CQSigImgMonitor 0 127 4"
                    "analogMonitor 0 0"
                    "lvdsStreamCfg -1 0 1 0"
                    "bpmCfg -1 0 0 0"
                    ];
            elseif obj.num == 2
                % Create CLI command string array for 77 GHz radar AWR1642
                obj.cliCommands = [
                    "sensorStop"
                    "flushCfg"
                    "dfeDataOutputMode 1"
                    "channelCfg 15 3 0"
                    "adcCfg 2 1"
                    "adcbufCfg -1 0 1 1 1"
                    %"profileCfg 0 77 429 7 57.14 0 0 70 1 256 5209 0 0 30"
                    "profileCfg 0 " + obj.f0_GHz + " " + obj.idleTime_us + " " + obj.adcStartTime_us + " " + obj.rampEndTime_us + ...
                    " 0 0 " + obj.K + " " + obj.txStartTime_us + " " + obj.adcSamples + " " + obj.fS_ksps + " 0 0 30"
                    "chirpCfg 0 0 0 0 0 0 0 1"
                    "chirpCfg 1 1 0 0 0 0 0 2"
                    %"frameCfg 0 1 16 0 100 1 0"
                    "frameCfg 0 1 " + obj.numChirps + " " + obj.numFrames + " " + obj.pri_ms + " 2 0" % the 2 at the end refers the hardware vs software trigger may need to change
                    "lowPower 0 0"
                    "guiMonitor -1 1 1 0 0 0 1"
                    "cfarCfg -1 0 2 8 4 3 0 15 1"
                    "cfarCfg -1 1 0 4 2 3 1 15 1"
                    "multiObjBeamForming -1 1 0.5"
                    "clutterRemoval -1 0"
                    "calibDcRangeSig -1 0 -5 8 256"
                    "extendedMaxVelocity -1 0"
                    "bpmCfg -1 0 0 1"
                    "lvdsStreamCfg -1 0 1 0"
                    "compRangeBiasAndRxChanPhase 0.0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0"
                    "measureRangeBiasAndRxChanPhase 0 1.5 0.2"
                    "CQRxSatMonitor 0 3 5 121 0"
                    "CQSigImgMonitor 0 127 4"
                    "analogMonitor 0 0"
                    "aoaFovCfg -1 -90 90 -90 90"
                    "cfarFovCfg -1 0 0 8.92"
                    "cfarFovCfg -1 1 -1 1.00"
                    ];
            end
        end
        
    end
end