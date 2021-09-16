classdef TI_Radar_Device < handle
    properties (Access = public)
        num                         % Indicates if the radar is 60 GHz (num==1) or 77 GHz (num==2)
        
        cliCommands                 % Array of strings containing the CLI commands
        cfgFilePath                 % Path to the profileN.cfg, where N = obj.num
        
        isApp = false               % Boolean whether or not to use the GUI functionality
        isConnected = false         % Boolean whether or not the radar is connected over serial
        isConfigured = false        % Boolean whether or not the radar is configured
        isNewConfiguration = true   % Boolean whether or not the the configuration is new or it has already been configured
        COMPort = []                % COM Port serialport object
        COMPortNum = 0              % COM Port number
        
        f0_GHz = 77                 % Starting frequency in GHz
        K = 124.996                 % Chirp slope in MHz/us
        idleTime_us = 10            % Idle time in us
        txStartTime_us = 0          % TX start time in us
        adcStartTime_us = 0         % ADC start time in us
        adcSamples = 64             % Number of ADC samples
        fS_ksps = 2000              % Sample frequency in ksps
        rampEndTime_us = 32         % Ramp end time in us
        numFrames = 0               % Number of frames
        numChirps = 4               % Number of chirps per frame
        pri_ms = 1                  % Pulse repetition interval (frame periodicity)
        nRx = 4                     % Number of receive antennas used
        nTx = 2                     % Number of transmit antennas used
        c = 299792458               % Speed of light
        
        triggerSelect = 2          	% 1 for SW trigger, 2 for HW trigger
        
        % GUI related parameters
        connectionLamp              % Lamp in the GUI for the radar connection
        configurationLamp           % Lamp in the GUI for the radar configuration
        textArea                    % Text area in the GUI for showing statuses
        app                         % GUI object handle
        
        % Chirp parameter fields
        f0_GHz_field                % Edit field in GUI for f0_GHz
        K_field                     % Edit field in GUI for K
        idleTime_us_field           % Edit field in GUI for idleTime_us
        txStartTime_us_field        % Edit field in GUI for txStartTime_us
        adcStartTime_us_field       % Edit field in GUI for adcStarTime_us
        adcSamples_field            % Edit field in GUI for adcSamples
        fS_ksps_field               % Edit field in GUI for fS_ksps
        rampEndTime_us_field        % Edit field in GUI for rampEndTime_us
        numFrames_field             % Edit field in GUI for numFrames
        numChirps_field             % Edit field in GUI for numChirps
        pri_ms_field                % Edit field in GUI for pri_ms
        HardwareTrigger_checkbox    % Check box in GUI for whether or not to use HW trigger
    end
    
    methods
        function obj = TI_Radar_Device(num)
            obj.num = num;
        end
        
        function err = SerialConnect(obj)
            % Connect TI radar over serial
            %
            % Outputs
            %   1   :   Successfully connected to serial
            %   -1  :   Failed to connect over serial
            
            % Prompt and choose serial port for ESP32
            [obj.COMPortNum,~,tf] = serialSelect("Select: ""XDS110 Class Application/User UART port:""");
            
            if tf
                serialPortName = "COM" + obj.COMPortNum;
                try
                    obj.COMPort = serialport(serialPortName,115200);
                    obj.textArea.Value = "Radar " + obj.num + " is connected on " + serialPortName;
                    configureTerminator(obj.COMPort,"CR");
                    obj.isConnected = true;
                    
                    pause(0.01)
                    obj.connectionLamp.Color = 'green';
                catch
                    obj.textArea.Value = "Unable to connect to " +  serialPortName + " is another application connected?";
                    err = -1;
                    return;
                end
                
                if obj.isApp
                    figure(obj.app.UIFigure);
                end
                err = 1;
            else
                % No serial port selected
                obj.textArea.Value = "Invalid COM port selected or no COM port selected. Verify connection and try again.";
                
                if obj.isApp
                    figure(obj.app.UIFigure);
                end
                err = -1;
            end
        end
        
        function SerialDisconnect(obj)
            if ~obj.isConnected
                obj.textArea.Value = "Radar is not connected. Cannot disconnect";
                return;
            end
            
            obj.COMPort = [];
            obj.COMPortNum = 0;
            
            obj.isConnected = false;
            obj.connectionLamp.Color = "red";
            
            obj.isConfigured = false;
            obj.configurationLamp.Color = "red";
        end
        
        function err = Update(obj)
            % Update the TI_Radar_Device
            %
            % Outputs
            %   1   :   Radar updated successfully
            %   -1  :   Radar did not update successfully
            
            if obj.isApp
                err = obj.Get();
            else
                err = 1;
            end
        end
        
        function err = Get(obj)
            % Attempts to get the values from the GUI
            %
            % Outputs
            %   1   :   Radar parameters are valid
            %   -1  :   Radar parameters are invalid
            
            if ~obj.isApp
                obj.textArea.Value = "ERROR: isApp must be set to true to get the values!";
                return;
            end
                    
            obj.f0_GHz = obj.f0_GHz_field.Value;
            obj.K = obj.K_field.Value;
            obj.idleTime_us = obj.idleTime_us_field.Value;
            obj.txStartTime_us = obj.txStartTime_us_field.Value;
            obj.adcStartTime_us = obj.adcStartTime_us_field.Value;
            obj.adcSamples = obj.adcSamples_field.Value;
            obj.fS_ksps = obj.fS_ksps_field.Value;
            obj.rampEndTime_us = obj.rampEndTime_us_field.Value;
            obj.numFrames = obj.numFrames_field.Value;
            obj.numChirps = obj.numChirps_field.Value;
            obj.pri_ms = obj.pri_ms_field.Value;
            obj.nRx = 4;
            obj.nTx = 2;
            obj.triggerSelect = 1 + obj.HardwareTrigger_checkbox.Value;
            
            err = obj.CheckRadarParameters();
        end
        
        function Configure(obj)
            if obj.Update() == -1
                return;
            end
            
            if ~obj.isConnected
                obj.textArea.Value = "Connect radar before configuring";
                return;
            end
            
            obj.configurationLamp.Color = "yellow";
            obj.textArea.Value = "Configuring Radar " + obj.num;
            
            obj.CreateCLICommands();
            obj.CreateCFG();
            if obj.WriteCLICommands() == -1
                obj.isConfigured = false;
                obj.configurationLamp.Color = "red";
                obj.textArea.Value = "Radar " + obj.num + " could not be configured!";
                return;
            end
            
            obj.isConfigured = true;
            obj.isNewConfiguration = true;
            obj.configurationLamp.Color = "green";
            obj.textArea.Value = "Radar " + obj.num + " configured!";
        end
        
        function Start(obj)
            if ~obj.isConnected
                obj.textArea.Value = "Connect radar before starting";
                return;
            end
            
            obj.textArea.Value = "Starting Radar " + obj.num;
            % Start the sensor
            try
                if obj.isNewConfiguration
                    writeline(obj.COMPort,'sensorStart');
                    obj.isNewConfiguration = false;
                else
                    writeline(obj.COMPort,'sensorStart 0');
                end
                obj.textArea.Value = "Radar " + obj.num + " started!";
            catch
                obj.Stop();
            end
        end
        
        function Stop(obj)
            % Stops the current radar capture by sending the "sensorStop"
            % command to the COM port
            try
                writeline(obj.COMPort,'sensorStop');
                obj.textArea.Value = "Radar " + obj.num + " stopped!";
            catch
                obj.textArea.Value = "SERIAL CONNECTION TO RADAR " + obj.num + " LOST!";
                obj.isConnected = false;
                obj.connectionLamp.Color = 'red';
                return;
            end
        end
        
        function err = WriteCLICommands(obj)
            % Writes the CLI commands to the radar over the serial
            % interface
            %
            % Outputs
            %   1   :   Successfully wrote all CLI commands
            %   -1  :   Failed to write CLI commands
            
            % Write CLI commands
            obj.COMPort.flush;
            try
                for indCLI = 1:length(obj.cliCommands)
                    %obj.cliCommands(indCLI)
                    
                    x = split(obj.cliCommands(indCLI));
                    if x(1) == "frameCfg"
                        pause(0.1);
                    end
                    
                    writeline(obj.COMPort,char(obj.cliCommands(indCLI)));
                    % Very important pause
                    pause(0.1);
                    
                    % For debugging
                    echo_str = readline(obj.COMPort);
                    if isempty(echo_str)
                        err = -1;
                        return;
                    end
                    done_str = readline(obj.COMPort);
                    prompt_str = read(obj.COMPort,size(char('mmwDemo:/>'),2),"char");
                    %                     disp(" ")
                    %                     disp("Input: " + obj.cliCommands(indCLI));
                    %                     disp("Echo : " + echo_str)
                    %                     disp("Done: " + done_str)
                    %                     disp("Prompt: " + prompt_str)
                    %                     disp(" ");
                    obj.textArea.Value = echo_str;
                end
                
                err = 1;
            catch
                obj.Stop();
                obj.textArea.Value = "Unable to read radar " + obj.num + " configuration file. Check for errors";
                return;
            end
        end
        
        function CreateCLICommands(obj)
            if obj.num == 1
                % Create CLI command string array for 60 GHz radar IWR6843ISK
                obj.cliCommands = [
                    "sensorStop"
                    "flushCfg"
                    "dfeDataOutputMode 1"
                    "channelCfg 15 5 0"
                    "adcCfg 2 1"
                    "adcbufCfg -1 0 1 1 1"
                    "lowPower 0 0"
                    %"profileCfg 0 60 7 3 24 0 0 166 1 256 12500 0 0 30"
                    "profileCfg 0 " + obj.f0_GHz + " " + obj.idleTime_us + " " + obj.adcStartTime_us + " " + obj.rampEndTime_us + ...
                    " 0 0 " + obj.K + " " + obj.txStartTime_us + " " + obj.adcSamples + " " + obj.fS_ksps + " 0 0 30"
                    "chirpCfg 0 0 0 0 0 0 0 1"
                    "chirpCfg 1 1 0 0 0 0 0 4"
                    %"frameCfg 0 1 1 0 100 1 0"
                    "frameCfg 0 1 " + obj.numChirps + " " + obj.numFrames + " " + obj.pri_ms + " " + obj.triggerSelect + " 0" % the 2 at the end refers the hardware vs software trigger may need to change
                    "guiMonitor -1 1 1 1 0 0 1"
                    "cfarCfg -1 0 2 8 4 3 0 15 1"
                    "cfarCfg -1 1 0 4 2 3 1 15 1"
                    "multiObjBeamForming -1 1 0.5"
                    "clutterRemoval -1 0"
                    "calibDcRangeSig -1 0 -5 8 256"
                    "extendedMaxVelocity -1 0"
                    "bpmCfg -1 0 0 0"
                    "lvdsStreamCfg -1 0 1 0"
                    "compRangeBiasAndRxChanPhase 0.0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0"
                    "measureRangeBiasAndRxChanPhase 0 1.5 0.2"
                    "CQRxSatMonitor 0 3 5 121 0"
                    "CQSigImgMonitor 0 127 4"
                    "analogMonitor 0 0"
                    "aoaFovCfg -1 -90 90 -90 90"
                    "cfarFovCfg -1 0 0 8.92"
                    "cfarFovCfg -1 1 -1 1.00"
                    "calibData 0 0 0"
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
                    %"profileCfg 0 77 10 0 32 0 0 124.996 1 64 2000 0 0 30"
                    "profileCfg 0 " + obj.f0_GHz + " " + obj.idleTime_us + " " + obj.adcStartTime_us + " " + obj.rampEndTime_us + ...
                    " 0 0 " + obj.K + " " + obj.txStartTime_us + " " + obj.adcSamples + " " + obj.fS_ksps + " 0 0 30"
                    "chirpCfg 0 0 0 0 0 0 0 1"
                    "chirpCfg 1 1 0 0 0 0 0 2"
                    %"frameCfg 0 1 4 0 50 1 0"
                    "frameCfg 0 1 " + obj.numChirps + " " + obj.numFrames + " " + obj.pri_ms + " " + obj.triggerSelect + " 0" % the 2 at the end refers the hardware vs software trigger may need to change
                    "lowPower 0 1"
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
                    "calibData 0 0 0"
                    ];
            end
        end
        
        function CreateCFG(obj)
            % Makes the .cfg profile configuration file
            
            % Set the correct path
            obj.cfgFilePath = cd + "\scripts\profile" + obj.num + ".cfg";
            
            fid = fopen(obj.cfgFilePath,"wt");
            
            if fid == -1
                obj.textArea.Value = "Error opening cfg file at " + obj.cfgFilePath;
            end
            
            % Print the json string
            fprintf(fid,'%s\n',obj.cliCommands);
            
            fclose(fid);
        end
        
        function err = CheckRadarParameters(obj)
            % Checks if the chirp parameters will work with the SDK
            %
            % Outputs
            %   1   :   Radar parameters are valid
            %   -1  :   Radar parameters are invalid
            
            if mod(obj.numChirps,4) ~= 0
                % Reduce to value that is multiple of 4
                obj.numChirps = obj.numChirps - mod(obj.numChirps,4);
            end

            % Ensure memory usage is OK
            if obj.adcSamples * obj.numChirps > 16384
                obj.textArea.Value = "Out of limits on chirp parameters!";
                obj.configurationLamp.Color = 'red';
                obj.isConfigured = false;

                cpN = 16384/ADCSamples;
                adcN = 16384/NumChirpLoops;
                obj.textArea.Value = "To resolve reduce to " + floor(cpN) + " chirp loops " + " - Reduce to " + floor(adcN) + " ADC samples";
                
                err = -1;
            else
                err = 1;
            end
        end
        
        function Calibrate(obj)
            % Do the corner reflector calibration process and save the data
            
            if ~obj.isConnected
                obj.textArea.Value = "Must connect radar " + obj.num + " before attempting to calibrate!";
                return;
            end
            
            if ~obj.isConfigured
                obj.textArea.Value = "Must configure radar" + obj.num + " before attempting to calibrate!";
                return;
            end
            
            % Confirm with the user
            msg = "Are you sure you would like to calibrate radar " + obj.num + "? " +...
                "A corner reflector is required and the existing calibration data will be overwritten! " +...
                "Radar must be moved into position before attempting calibration! " +...
                "Place lowest Rx element in line with corner reflector (at origin).";
            title = "Do Corner Reflector Calibration";
            selection = uiconfirm(obj.app.UIFigure,msg,title,...
                'Options',{'Yes','No'},...
                'DefaultOption',2,'CancelOption',2);
            
            if selection == "No"
                obj.textArea.Value = "Canceling radar " + obj.num + " calibration";
                return;
            end
            
            obj.textArea.Value = "Attempting to calibrate radar " + obj.num;
            
            % Store the temporary properties
            dca = obj.app.("dca" + obj.num);
            temp.numFrames = obj.numFrames;
            temp.triggerSelect = obj.triggerSelect;
            temp.fileName = dca.fileName;
            temp.folderName = dca.folderName;
            
            % Change the folder to store the data
            dca.fileName = "cal1";
            dca.folderName = "cal" + obj.num;
            dca.Prepare();
            
            % Change the trigger select
            obj.triggerSelect = 1;
            obj.HardwareTrigger_checkbox.Value = 0;
            
            % Get the calibration parameters
            prompt = {'Enter number of frames:','Enter distance from radar to corner reflector (mm):'};
            dlgtitle = 'Calibration Parameters';
            dims = [1,35];
            definput = {'2048','300'};
            answer = inputdlg(prompt,dlgtitle,dims,definput);
            
            if isempty(answer)
                obj.textArea.Value = "Canceling radar " + obj.num + " calibration";
                obj.triggerSelect = temp.triggerSelect;
                obj.HardwareTrigger_checkbox.Value = obj.triggerSelect - 1;
                dca.fileName = temp.fileName;
                dca.folderName = temp.folderName;
                figure(obj.app.UIFigure);
                return;
            end
            z0_mm = str2double(answer{2});
            
            if z0_mm < 250
                obj.textArea.Value = "Must calibrate with distance from radar to corner reflector greater than 250mm";
                obj.textArea.Value = "Canceling radar " + obj.num + " calibration";
                obj.triggerSelect = temp.triggerSelect;
                obj.HardwareTrigger_checkbox.Value = obj.triggerSelect - 1;
                dca.fileName = temp.fileName;
                dca.folderName = temp.folderName;
                figure(obj.app.UIFigure);
                return;
            end
            
            obj.numFrames = str2double(answer{1});
            obj.numFrames_field.Value = obj.numFrames;
            
            % Configure the radar
            obj.Configure();
            
            % Start the capture
            dca.Start();
            obj.Start();
            
            % Wait for data to be collected
            pause(obj.numFrames * obj.pri_ms*1e-3 + 5)
            
            % Stop the capture
            obj.Stop();
            dca.Stop();
            
            pause(1);
            
            % Read in the data
            d = Data_Reader();
            d.nRx = 4;
            d.nTx = 2;
            d.numChirps = obj.numChirps;
            d.numX = obj.numFrames;
            d.numADC = obj.adcSamples;
            calFilePath = cd + "/data/cal" + obj.num + "/" + dca.fileName + "_Raw_0.bin";
            if d.VerifyFile(calFilePath) == 1
                data = d.ReadFile(calFilePath);
            end
            
            % Simulate the scenario
            if obj.num == 1
                fmcw.fC = 62e9;
            else
                fmcw.fC = 79e9;
            end
            fmcw.c = 299792458;
            fmcw.f0 = obj.f0_GHz*1e9;
            fmcw.K = obj.K*1e12;
            fmcw.IdleTime_s = obj.idleTime_us*1e-6;
            fmcw.TXStartTime_s = obj.txStartTime_us*1e-6;
            fmcw.ADCStartTime_s = obj.adcStartTime_us*1e-6;
            fmcw.ADCSamples = obj.adcSamples;
            fmcw.fS = obj.fS_ksps*1e3;
            fmcw.RampEndTime_s = obj.rampEndTime_us*1e-6;
            fmcw.lambda_m = fmcw.c/fmcw.fC;
            fmcw.k = 2*pi/fmcw.c*(fmcw.f0 + fmcw.ADCStartTime_s*fmcw.K + fmcw.K*(0:fmcw.ADCSamples-1)/fmcw.fS);
            fmcw.rangeMax_m = fmcw.fS*fmcw.c/(2*fmcw.K);
            target.xyz_m = [0,0,z0_mm*1e-3];
            rx.xyz_m = [zeros(4,2),fmcw.lambda_m/4*(0:3)'];
            tx.xyz_m = [zeros(2,2),fmcw.lambda_m/2*(0:1)'+ fmcw.lambda_m*3/4];
            Rt = pdist2(tx.xyz_m,target.xyz_m)';
            Rr = pdist2(rx.xyz_m,target.xyz_m);
            
            k = reshape(fmcw.k,1,1,[]);
            sarData = exp(1j*(Rt+Rr).*k);
            sarDataFFT = fft(sarData,2048,3);
            
            % Get good phase thetaGood
            [~,indZIdeal] = max(squeeze(mean(sarDataFFT,[1,2])));
            rangeAxis_m = linspace(0,fmcw.rangeMax_m-fmcw.rangeMax_m/2048,2048).';
            zIdeal_m = rangeAxis_m(indZIdeal);
            thetaGood = angle(sarDataFFT(:,:,indZIdeal));
            
            % Get zBias_m offset between measured and ideal z
            data = squeeze(mean(data,[3,4]));
            dataFFT = fft(data,2048,3);
            avgDataFFT = squeeze(mean(dataFFT,[1,2]));
            [~,indZMeasured] = max(avgDataFFT .* (rangeAxis_m > 0.2 & rangeAxis_m < 1));
            zMeasured_m = rangeAxis_m(indZMeasured);
            
            zBias_m = zIdeal_m - zMeasured_m;
            
            % Attempt range correction
            dataFFT = fft(data .* exp(1j*2*k*zBias_m),2048,3);
            
            % Get bad phase thetaBad
            avgDataFFT = squeeze(mean(dataFFT,[1,2]));
            [~,indZMeasured] = max(avgDataFFT .* (rangeAxis_m > 0.2 & rangeAxis_m < 1));
            % debug: zMeasured_m = rangeAxis_m(indZMeasured);
            thetaBad = angle(dataFFT(:,:,indZMeasured));
            
            sarDataCal = exp(1j*(thetaGood-thetaBad));
            
            save(cd + "/data/cal" + obj.num,"sarDataCal","zBias_m");
            
            % Move back the temporary properties
            obj.numFrames = temp.numFrames;
            obj.numFrames_field.Value = obj.numFrames;
            obj.triggerSelect = temp.triggerSelect;
            obj.HardwareTrigger_checkbox.Value = obj.triggerSelect - 1;
            dca.fileName = temp.fileName;
            dca.folderName = temp.folderName;
        end
    end
end