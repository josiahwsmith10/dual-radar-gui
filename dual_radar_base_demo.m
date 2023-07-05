% NOTES: The AMC4030_Device class uses 3-axes: hor, ver, rot, but the dual
% radar base has X, Z, and theta because the "ver" axis moves the target in
% the z-direction (towards or away from the radar), not vertically up or
% down.

%% Add Folders
addpath(genpath("./"))

%% Create AMC4030
amc = AMC4030_Device();

%% Connect AMC4030 (COM4)
amc.SerialConnect();

%% Configure AMC4030
amc.hor_speed_mms = 20;
amc.hor_speed_home_mms = 5;
amc.hor_home_offset_mm = 0;
amc.hor_mm_per_rev = 5;
amc.hor_pulses_per_rev = 20000;

amc.ver_speed_mms = 20;
amc.ver_speed_home_mms = 5;
amc.ver_home_offset_mm = 0;
amc.ver_mm_per_rev = 5;
amc.ver_pulses_per_rev = 20000;

amc.rot_speed_degs = 20;
amc.rot_mm_per_rev = 36;
amc.rot_pulses_per_rev = 20000;
amc.Configure();

%% Send Single Command to Move Base Scanner
x_move_mm = 10;
z_move_mm = 10;
theta_move_mm = 10;

amc.SingleCommand(x_move_mm,z_move_mm,theta_move_mm);