classdef DCA_Device < handle
    properties
        isApp = false           % Boolean whether or not to use the GUI functionality
        num                     % Indicates if the radar is 60 GHz (num=1) or 77 GHz (num=2)
        
        isPrepared = false      % Boolean whether or not the DCA is prepared
        
        systemIPAddress         % System IP address of the DCA board as a string
        DCA1000IPAddress        % DCA1000IP address as a string
        configPort              % Configuration port as a string
        dataPort                % Data port as a string
        
        jsonFilePath            % Path of the json file
        jsonString              % json string to be written to the json file
        fileName                % File name to save data to (without extension)
        folderName = "test"     % Folder name to save data to
        
        % GUI related parameters
        prepareLamp             % Lamp in the GUI to indicate if the DCA is prepared
        textArea                % Text area in the GUI for showing statuses
        app                         % GUI object handle
        
        % DCA fields
        mmWaveStudioPath        % Path to the mmWave Studio installation
        systemIPAddress_field   % Edit field in the GUI for the system IP address
        DCA1000IPAddress_field  % Edit field in the GUI for the DCA IP address
        configPort_field        % Edit field in the GUI for the configuration port
        dataPort_field          % Edit field in the GUI for the data port
        fileName_field          % Edit field in the GUI for the file name
    end
    
    methods
        function obj = DCA_Device(num)
            obj.num = num;
        end
        
        function Update(obj)
            % Update the DCA_Device
            
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
            
            obj.systemIPAddress = obj.systemIPAddress_field.Value;
            obj.DCA1000IPAddress = obj.DCA1000IPAddress_field.Value;
            obj.configPort = obj.configPort_field.Value;
            obj.dataPort = obj.dataPort_field.Value;
            obj.fileName = obj.fileName_field.Value;
        end
        
        function Prepare(obj)
            % Prepare the DCA1000EVM (create cf<num>.json config file)
            
            obj.Update();
            
            obj.jsonFilePath = obj.mmWaveStudioPath + "\PostProc\cf" + obj.num + ".json";
            
            obj.CreateJSONString();
            obj.CreateJSON();
            
            obj.CreateDCAStartPS();
            obj.CreateDCAStopPS();
            obj.isPrepared = true;
            obj.prepareLamp.Color = 'green';
        end
        
        function CreateJSON(obj)
            fid = fopen(obj.jsonFilePath,"wt");
            
            if fid == -1
                obj.textArea.Value = "Error opening json file at " + obj.jsonFilePath;
            end
            
            % Print the json string
            fprintf(fid,'%s\n',obj.jsonString);
            
            fclose(fid);
        end
        
        function CreateJSONString(obj)
            obj.jsonString = ["{"
                "  ""DCA1000Config"": {"
                "    ""dataLoggingMode"": ""raw"","
                "    ""dataTransferMode"": ""LVDSCapture"","
                "    ""dataCaptureMode"": ""ethernetStream"","
                "    ""lvdsMode"": 2,"
                "    ""dataFormatMode"": 3,"
                "    ""packetDelay_us"": 25,"
                "    ""ethernetConfig"": {"
                "      ""DCA1000IPAddress"": """ + obj.DCA1000IPAddress + ""","
                "      ""DCA1000ConfigPort"": " + obj.configPort + ","
                "      ""DCA1000DataPort"": " + obj.dataPort + ""
                "    },"
                "    ""ethernetConfigUpdate"": {"
                "      ""systemIPAddress"": """ + obj.systemIPAddress + ""","
                "      ""DCA1000IPAddress"": """ + obj.DCA1000IPAddress + ""","
                "      ""DCA1000MACAddress"": ""12.34.56.78.90.12"","
                "      ""DCA1000ConfigPort"": " + obj.configPort + ","
                "      ""DCA1000DataPort"": " + obj.dataPort + ""
                "    },"
                "    ""captureConfig"": {"
                "      ""fileBasePath"": """ + strrep(cd + "\data\" + obj.folderName,"\","\\") + ""","
                "      ""filePrefix"": """ + obj.fileName + ""","
                "      ""maxRecFileSize_MB"": 1024,"
                "      ""sequenceNumberEnable"": 0,"
                "      ""captureStopMode"": ""infinite"","
                "      ""bytesToCapture"": 4000,"
                "      ""durationToCapture_ms"": 4000,"
                "      ""framesToCapture"": 40"
                "    },"
                "    ""dataFormatConfig"": {"
                "      ""MSBToggle"": 0,"
                "      ""laneFmtMap"": 0,"
                "      ""reorderEnable"": 0,"
                "      ""dataPortConfig"": ["
                "        {"
                "          ""portIdx"": 0,"
                "          ""dataType"": ""real"""
                "        },"
                "        {"
                "          ""portIdx"": 1,"
                "          ""dataType"": ""complex"""
                "        },"
                "        {"
                "          ""portIdx"": 2,"
                "          ""dataType"": ""real"""
                "        },"
                "        {"
                "          ""portIdx"": 3,"
                "          ""dataType"": ""real"""
                "        },"
                "        {"
                "          ""portIdx"": 4,"
                "          ""dataType"": ""complex"""
                "        }"
                "      ]"
                "    }"
                "  }"
                "}"];
        end
        
        function CreateDCAStartPS(obj)
            fid = fopen(".\scripts\dcaStart" + obj.num + ".ps1","wt");
            % cd to mmWaveStudio\PostProc\
            fprintf(fid,'%s\n',"cd " + obj.mmWaveStudioPath + "\PostProc\");
            % print fpga command
            fprintf(fid,'%s\n',".\DCA1000EVM_CLI_Control.exe fpga cf" + obj.num + ".json");
            % print record command
            fprintf(fid,'%s\n',".\DCA1000EVM_CLI_Control.exe record cf" + obj.num + ".json");
            % print start command
            fprintf(fid,'%s\n',".\DCA1000EVM_CLI_Control.exe start_record cf" + obj.num + ".json");
            fclose(fid);
        end
        
        function CreateDCAStopPS(obj)
            fid = fopen(".\scripts\dcaStop" + obj.num + ".ps1","wt");
            % cd to mmWaveStudio\PostProc\
            fprintf(fid,'%s\n',"cd " + obj.mmWaveStudioPath + "\PostProc\");
            % print stop command
            fprintf(fid,'%s\n',".\DCA1000EVM_CLI_Control.exe stop_record cf" + obj.num + ".json");
            fclose(fid);
        end
        
        function Start(obj)
            if ~obj.isPrepared
                obj.textArea.Value = "Prepare the DCAs before starting!";
                return
            end
            
            !powershell Set-ExecutionPolicy -Scope CurrentUser Bypass
            pause(0.05)
            if obj.num == 1
                !powershell -windowstyle hidden -file .\scripts\dcaStart1.ps1
            elseif obj.num == 2
                !powershell -windowstyle hidden -file .\scripts\dcaStart2.ps1
            end
            pause(0.05)
            !powershell Set-ExecutionPolicy -Scope CurrentUser Default
            obj.textArea.Value = "Press ""Stop Radar " + obj.num + """ to end capture";
            pause(0.1)
        end
        
        function Stop(obj)
            !powershell Set-ExecutionPolicy -Scope CurrentUser Bypass
            pause(0.05)
            if obj.num == 1
                !powershell -windowstyle hidden -file .\scripts\dcaStop1.ps1
            elseif obj.num == 2
                !powershell -windowstyle hidden -file .\scripts\dcaStop2.ps1
            end
            pause(0.05)
            !powershell Set-ExecutionPolicy -Scope CurrentUser Default
            obj.textArea.Value = "Radar " + obj.num + " stopped";
            pause(0.1)
        end
    end
end