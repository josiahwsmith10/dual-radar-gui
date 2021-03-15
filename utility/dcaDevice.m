classdef dcaDevice
    properties
        num
        
        prepareLamp
        textArea
        mmWaveStudioPath
        
        isPrepared
        
        systemIPAddress
        DCA1000IPAddress
        configPort
        dataPort
        
        jsonFilePath
        jsonString
    end
    methods
        function obj = dcaDevice(app,num)
            obj.num = num;
            obj.textArea = app.MainTextArea;
            obj.mmWaveStudioPath = app.mmWavePath;
            
            obj.isPrepared = false;
            obj.prepareLamp.Color = 'red';
        end
        
        function obj = startDataReader(obj)
            system("start ./include/dca1000evm_udp_interface.exe " + app.ADCSamplesEditField.Value + " " + 8 + " " + 1 + " " + ".\data\" + string(app.Params.fileName));
        end
        
        function obj = prepareDCA(obj)
            obj.jsonFilePath = cd + "\scripts\cf" + obj.num + ".json";
            
            obj = createJSONString(obj);
            obj = createJSON(obj);
            
            obj = createDCAStartPS(obj);
            obj = createDCAStopPS(obj);
            obj.isPrepared = true;
            obj.prepareLamp.Color = 'green';
        end
        
        function obj = createJSON(obj)
            fid = fopen(obj.jsonFilePath,"wt");
            % Print every line of the json string
            for indLine = 1:length(obj.jsonString)
                fprintf(fid,'%s\n',obj.jsonString(indLine));
            end
            fclose(fid);
        end
        
        function obj = createJSONString(obj)
            obj.jsonString = ["{"
                "  ""DCA1000Config"": {"
                "    ""dataLoggingMode"": ""raw"","
                "    ""dataTransferMode"": ""LVDSCapture"","
                "    ""dataCaptureMode"": ""ethernetStream"","
                "    ""lvdsMode"": 1,"
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
                "      ""fileBasePath"": ""D:\\git\\ar1xxx_mmwavestudio_bitbucket\\mmWaveStudioPkg\\mmWaveStudio_Internal\\PostProc"","
                "      ""filePrefix"": ""lua_check"","
                "      ""maxRecFileSize_MB"": 1024,"
                "      ""sequenceNumberEnable"": 1,"
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
        
        function obj = createDCAStartPS(obj)
            fid = fopen(".\scripts\dcaStart" + obj.num + ".ps1","wt");
            % cd to mmWaveStudio\PostProc\
            fprintf(fid,'%s\n',"cd " + obj.mmWaveStudioPath + "\PostProc\");
            % print fpga command
            fprintf(fid,'%s\n',".\DCA1000EVM_CLI_Control.exe fpga " + obj.jsonFilePath);
            % print record command
            fprintf(fid,'%s\n',".\DCA1000EVM_CLI_Control.exe record " + obj.jsonFilePath);
            % print start command
            fprintf(fid,'%s\n',".\DCA1000EVM_CLI_Control.exe start_record " + obj.jsonFilePath);
            fclose(fid);
        end
        
        function obj = createDCAStopPS(obj)
            fid = fopen(".\scripts\dcaStop" + obj.num + ".ps1","wt");
            % cd to mmWaveStudio\PostProc\
            fprintf(fid,'%s\n',"cd " + obj.mmWaveStudioPath + "\PostProc\");
            % print stop command
            fprintf(fid,'%s\n',".\DCA1000EVM_CLI_Control.exe stop_record " + obj.jsonFilePath);
            fclose(fid);
        end
        
        function obj = startDCA(obj)
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
    end
end