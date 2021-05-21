%% Add Directories to MATLAB Path
addpath(genpath("../"))

% Folder Structure:
%
% SAR Scanner
%   - data (data from the radar is saved here automatically)
%   - docs (put the documentation you are making here)
%   - include (contains the libraries for the AMC4030)
%   - scripts (contains the powershell scripts generated for controling the
%   DCA boards)
%   - utilities (contains the various class definitions in MATLAB files)
%       - functions (folder containing functions called by the utilities)
%       - DCA_Device.m (class definition for the DCA board)
%       - Drawer_Device.m (class definition for the drawer - this is where
%       Yusef will be making changes)
%       - MCU_Device.m (class definition for the microcontroller - this is
%       where Ben will be making changes
%       - SAR_Scanner_Device.m (class definition for the AMC4030 motion
%       controller)
%       - TI_Radar_Device.m (class definition for the TI radar class)

%% Create Objects
% Use num = 1 for 60 GHz
%     num = 2 for 77 GHz
num = 1;

dca = DCA_Device([],1);
radar = TI_Radar_Device([],1);
amc = AMC4030_Device([]); % drawer = Drawer_Device([]);
esp = ESP32_Device([]);
scanner = SAR_Scanner_Device([],amc,79);

%% 1. Connect to Radar (Make sure to disconnect later)
radar.SerialConnect([]);

radar.connectionLamp.Color
% Should be 'green' if connection is successful

%% 3. Connect to the AMC4030 (Yusef: replace the amc controller with the drawer code)
amc.SerialConnect([]);

amc.connectionLamp.Color
% Should be 'green' if connection is successful

%% 4. Connect to the ESP32 (Ben: needs to be implemented)
esp.SerialConnect([]);

esp.connectionLamp.Color
% Should be 'green' if connection is successful

%% 5. Prepare DCA
dca.systemIPAddress = "192.168.33.30";
dca.DCA1000IPAddress = "192.168.33.180";
dca.configPort = "4096";
dca.dataPort = "4098";

dca.mmWaveStudioPath = "C:\ti\mmwave_studio_02_01_01_00\mmWaveStudio";

dca.Prepare();

dca.prepareLamp.Color
% Should be 'green' if configuration is successful

%% 6. Configure Radar
radar.f0_GHz = 60; % MUST conform to choice of num=1
radar.K = 124.996;
radar.idleTime_us = 10;
radar.txStartTime_us = 0;
radar.adcStartTime_us = 0;
radar.adcSamples = 64;
radar.fS_ksps = 2000;
radar.rampEndTime_us = 32;
radar.numFrames = 0;
radar.numChirps = 4;
radar.pri_ms = 50;

radar.triggerSelect = 2; % 1 for SW trigger, 2 for HW trigger

radar.Configure();

radar.configurationLamp.Color
% Should be 'green' if configuration is successful

%% 6a. Test if the Radar is Working
dca.Start();
radar.Start();

%% 6b. Stop the Radar
radar.Stop();
dca.Stop();

%% 7. Configure the Scan
scanner.xStep_m = scanner.lambda_m/4;
scanner.yStep_m = scanner.lambda_m*2;

scanner.numX = 256;
scanner.numY = 32;

scanner.xSize_m = 0.25;
scanner.ySize_m = 0.25;

scanner.method = "Rectilinear";

scanner.Configure();

%% 8. Configure ESP32
esp32.Configure();

esp32.configurationLamp.Color
% Should be 'green' if configuration is successful

%% 9. Start the Scan
scanner.Start();

%% 10. Disconnect Radar
radar.SerialDisconnect();

radar.connectionLamp.Color
% Should be 'red' if disconnection is successful

%% 11. Disconnect the ESP32
esp.SerialDisconnect();

esp.connectionLamp.Color
% Should be 'red' if disconnection is succesful