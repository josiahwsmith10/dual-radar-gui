classdef DCA_Device < handle
    properties
        num                 % Indicates if the radar is 60 GHz (num=1) or 77 GHz (num=2)
        
        prepareLamp         % Lamp in the GUI to indicate if the DCA is prepared
        textArea            % Text area in the GUI for showing statuses
        mmWaveStudioPath    % Path to the mmWave Studio installation
        
        isPrepared          % Boolean whether or not the DCA is prepared
        
        systemIPAddress     % System IP address of the DCA board as a string
        DCA1000IPAddress    % DCA1000IP address as a string
        configPort          % Configuration port as a string
        dataPort            % Data port as a string
        
        jsonFilePath        % Path of the json file
        jsonString          % json string to be written to the json file
        fileName            % File name to save data to (without extension)
    end
    methods
        function obj = DCA_Device(app,num)
            obj.num = num;
            
            if ~isempty(app)
                obj.textArea = app.MainTextArea;
                obj.mmWaveStudioPath = app.mmWavePath;
            end
            
            obj.isPrepared = false;
            obj.prepareLamp.Color = 'red';
        end
        
        function obj = StartDataReader(obj)
            system("start ./include/dca1000evm_udp_interface.exe " + app.ADCSamplesEditField.Value + " " + 8 + " " + 1 + " " + ".\data\" + string(app.Params.fileName));
        end
        
        function obj = Prepare(obj)
            obj.jsonFilePath = obj.mmWaveStudioPath + "\PostProc\cf" + obj.num + ".json";
            
            obj = CreateJSONString(obj);
            obj = CreateJSON(obj);
            
            obj = CreateDCAStartPS(obj);
            obj = CreateDCAStopPS(obj);
            obj.isPrepared = true;
            obj.prepareLamp.Color = 'green';
        end
        
        function obj = CreateJSON(obj)
            fid = fopen(obj.jsonFilePath,"wt");
            
            if fid == -1
                obj.textArea.Value = "Error opening json file at " + obj.jsonFilePath;
            end
            
            % Print every line of the json string
            for indLine = 1:length(obj.jsonString)
                fprintf(fid,'%s\n',obj.jsonString(indLine));
            end
            
            fclose(fid);
        end
        
        function obj = CreateJSONString(obj)
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
                "      ""fileBasePath"": """ + strrep(cd + "\data","\","\\") + ""","
                "      ""filePrefix"": """ + obj.fileName + ""","
                "      ""maxRecFileSize_MB"": 1024,"
                "      ""sequenceNumberEnable"": 1,"
                "      ""captureStopMode"": ""infinite"","
                "      ""bytesToCapture"": 8388608,"
                "      ""durationToCapture_ms"": 40000,"
                "      ""framesToCapture"": 256"
                "    },"
                "    ""dataFormatConfig"": {"
                "      ""MSBToggle"": 0,"
                "      ""laneFmtMap"": 0,"
                "      ""reorderEnable"": 1,"
                "      ""dataPortConfig"": ["
                "        {"
                "          ""portIdx"": 0,"
                "          ""dataType"": ""complex"""
                "        },"
                "        {"
                "          ""portIdx"": 1,"
                "          ""dataType"": ""complex"""
                "        },"
                "        {"
                "          ""portIdx"": 2,"
                "          ""dataType"": ""complex"""
                "        },"
                "        {"
                "          ""portIdx"": 3,"
                "          ""dataType"": ""complex"""
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
        
        function obj = CreateDCAStartPS(obj)
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
        
        function obj = CreateDCAStopPS(obj)
            fid = fopen(".\scripts\dcaStop" + obj.num + ".ps1","wt");
            % cd to mmWaveStudio\PostProc\
            fprintf(fid,'%s\n',"cd " + obj.mmWaveStudioPath + "\PostProc\");
            % print stop command
            fprintf(fid,'%s\n',".\DCA1000EVM_CLI_Control.exe stop_record cf" + obj.num + ".json");
            fclose(fid);
        end
        
        function obj = Start(obj)
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
        
        function obj = Stop(obj)
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