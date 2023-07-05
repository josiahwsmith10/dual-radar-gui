function setupAMC_DRB(app)
% Assigns the properties of the GUI to the AMC4030_Device object for the
% dual radar base GUI

app.amc.connectionLamp = app.AMC4030ConnectionLamp;
app.amc.configurationLamp = app.AMC4030ConfigurationLamp;
app.amc.textArea = app.MainTextArea;
app.amc.app = app;

% Horizontal
app.amc.hor_speed_field = app.XSpeedmmsEditField;
app.amc.hor_home_speed_field = app.XHomespeedmmsEditField;
app.amc.hor_home_offset_field = app.XHomeoffsetmmEditField;
app.amc.hor_max_field = app.XMaximummmEditField;
app.amc.hor_mm_rev_field = app.XmmrevEditField;
app.amc.hor_pulses_rev_field = app.XpulsesrevEditField;

% Vertical
app.amc.ver_speed_field = app.ZSpeedmmsEditField;
app.amc.ver_home_speed_field = app.ZHomespeedmmsEditField;
app.amc.ver_home_offset_field = app.ZHomeoffsetmmEditField;
app.amc.ver_max_field = app.ZMaximummmEditField;
app.amc.ver_mm_rev_field = app.ZmmrevEditField;
app.amc.ver_pulses_rev_field = app.ZpulsesrevEditField;

% Rotational
app.amc.rot_speed_field = app.ThetaSpeedmmsEditField;
app.amc.rot_mm_rev_field = app.ThetammrevEditField;
app.amc.rot_pulses_rev_field = app.ThetapulsesrevEditField;

app.amc.curr_hor_field = app.XPositionmmEditField;
app.amc.curr_ver_field = app.ZPositionmmEditField;
app.amc.curr_rot_field = app.ThetaPositionmmEditField;

app.amc.isApp = true;
app.amc.Update();
end