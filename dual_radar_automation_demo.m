% V1: Josiah Smith
% TODO: Create checking mecahnism so if scan fails, it repeats the same
% scan until it works

%% Add Folders
addpath(genpath("./"))

%% Create Objects
dca1 = DCA_Device(1);
dca2 = DCA_Device(2);
radar1 = TI_Radar_Device(1);
radar2 = TI_Radar_Device(2);
amc1 = AMC4030_Device(); % AMC4030 for dual radar scanner
amc2 = AMC4030_Device(); % AMC4030 for base scanner
esp = ESP32_Device();
scanner = SAR_Scanner_Device();

%% Connect Scanner Elements
scanner.dca1 = dca1;
scanner.dca2 = dca2;
scanner.radar1 = radar1;
scanner.radar2 = radar2;
scanner.amc = amc1;
scanner.esp = esp;

%% Connect Radar 1 (COM6)
radar1.SerialConnect();

%% Connect Radar 2 (COM5)
radar2.SerialConnect();

%% Connect AMC4030 (COM3)
amc1.SerialConnect();

%% Connect AMC4030 (COM4)
amc2.SerialConnect();

%% Connect ESP32 (COM17)
esp.SerialConnect();

%% Prepare DCA 1 (Should See "System Connected" Message)
dca1.systemIPAddress = "192.168.33.30";
dca1.DCA1000IPAddress = "192.168.33.180";
dca1.MACAddress = "12.34.56.78.90.12";
dca1.configPort = "4096";
dca1.dataPort = "4098";
dca1.Prepare();

%% Prepare DCA 2 (Should See "System Connected" Message)
dca2.systemIPAddress = "192.168.55.50";
dca2.DCA1000IPAddress = "192.168.55.180";
dca2.MACAddress = "12.34.56.78.90.55";
dca2.configPort = "4056";
dca2.dataPort = "4058";
dca2.Prepare();

%% Configure Radar 1
radar1.f0_GHz = 60;
radar1.K = 124.996;
radar1.idleTime_us = 10;
radar1.txStartTime_us = 0;
radar1.adcStartTime_us = 0;
radar1.adcSamples = 64;
radar1.fS_ksps = 2000;
radar1.rampEndTime_us = 32;
radar1.numFrames = 0;
radar1.numChirps = 4;
radar1.pri_ms = 1;
radar1.serialNumber = 0685; % Change if using a different radar
radar1.Configure();

%% Configure Radar 2
radar2.f0_GHz = 77;
radar2.K = 124.996;
radar2.idleTime_us = 10;
radar2.txStartTime_us = 0;
radar2.adcStartTime_us = 0;
radar2.adcSamples = 64;
radar2.fS_ksps = 2000;
radar2.rampEndTime_us = 32;
radar2.numFrames = 0;
radar2.numChirps = 4;
radar2.pri_ms = 1;
radar2.serialNumber = 0023; % Change if using a different radar
radar2.Configure();

%% Configure Dual Radar Scanner AMC4030
amc1.hor_speed_mms = 200;
amc1.hor_speed_home_mms = 50;
amc1.hor_home_offset_mm = 0;
amc1.hor_mm_per_rev = 110;
amc1.hor_pulses_per_rev = 20000;

amc1.ver_speed_mms = 50;
amc1.ver_speed_home_mms = 50;
amc1.ver_home_offset_mm = 0;
amc1.ver_mm_per_rev = 110;
amc1.ver_pulses_per_rev = 20000;

% Size of the linear actuators
amc1.hor_max_mm = 1000;
amc1.ver_max_mm = 1000;
amc1.Configure();

%% Configure Base Scanner AMC4030
amc2.hor_speed_mms = 20;
amc2.hor_speed_home_mms = 5;
amc2.hor_home_offset_mm = 0;
amc2.hor_mm_per_rev = 5;
amc2.hor_pulses_per_rev = 20000;

amc2.ver_speed_mms = 20;
amc2.ver_speed_home_mms = 5;
amc2.ver_home_offset_mm = 0;
amc2.ver_mm_per_rev = 5;
amc2.ver_pulses_per_rev = 20000;

amc2.rot_speed_degs = 20;
amc2.rot_mm_per_rev = 36;
amc2.rot_pulses_per_rev = 20000;
amc2.Configure();

%% Configure Scan
scanner.xMax_m = amc1.hor_max_mm*1e-3;
scanner.yMax_m = amc1.ver_max_mm*1e-3;
scanner.xStep_m = 0.948710310126*1e-3; % lambda/4 for 79 GHz
scanner.yStep_m = 7.589682481013*1e-3; % lambda*2 for 79 GHz
scanner.xOffset_m = 0; % Starts movement for xOffset_m meters, then starts scan
scanner.DeltaX_m = 188.5*1e-3;
scanner.numX = 256;
scanner.numY = 32;

scanner.fileName = "test0";
scanner.scanNotes = ""; % Some notes about the scan (size, speed, target, etc. useful for later reference)
scanner.radarSelect = 3; % 1: radar 1, 2: radar2, 3: dual radar

%% Home AMC4030
amc1.Home_AMC4030(1,1,0)

%% Move Dual Radar Scanner to Starting Position
x_move_mm = 10; % Starting offset in x-direction
y_move_mm = 10; % Starting offset in y-direction
scanner.SingleCommand(x_move_mm,y_move_mm);

%% Send Single Command to Move Base Scanner
x_move_mm = 10;
z_move_mm = 10;
theta_move_mm = 10;

amc2.SingleCommand(x_move_mm,z_move_mm,theta_move_mm);

%% Create Loop Settings
loop.xScan_mm = 0;
loop.yScan_mm = 0;
loop.thetaScan_deg = 0:10:350;

% NOTE: Make sure that the loop will not move the base scanner too far!

%% Run Loop

for x_mm = loop.xScan_mm
    for z_mm = loop.zScan_m
        for theta_deg = loop.thetaScan_deg
            % Move AMC4030
            amc2.SingleCommand(x_mm-amc2.curr_hor_mm,z_mm-amc2.curr_ver_mm,theta_deg-amc2.curr_rot_deg);

            % Set new scan name for every loop
            scanner.fileName = "loop_x"+x_mm+"mm_z"+z_mm+"mm_theta"+theta_deg+"deg";
            scanner.scanNotes = "<INSERT NOTE ABOUT TARGET>: x = "+x_mm+" mm, z = "+z_mm+" m theta = "+theta_deg+" deg";
            
            % Do scan and load files
            scanner.Start();
            scanner.Load();
        end
    end
end


%% Disconnect Radars and ESP32
radar1.SerialDisconnect();
radar2.SerialDisconnect();
esp.SerialDisconnect();
