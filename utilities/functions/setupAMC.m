function setupAMC(app)
% Assigns the properties of the GUI to the AMC4030_Device object

app.amc.connectionLamp = app.AMC4030ConnectionLamp;
app.amc.configurationLamp = app.AMC4030ConfigurationLamp;
app.amc.textArea = app.MainTextArea;
app.amc.app = app;

app.amc.hor_speed_field = app.XSpeedmmsEditField;
app.amc.ver_speed_field = app.YSpeedmmsEditField;

app.amc.hor_home_speed_field = app.HomeSpeedmmsEditField;
app.amc.hor_home_offset_field = app.HomeOffsetmmEditField;

app.amc.ver_home_speed_field = app.HomeSpeedmmsEditField;
app.amc.ver_home_offset_field = app.HomeOffsetmmEditField;

app.amc.hor_mm_rev_field = app.XmmrevEditField;
app.amc.hor_pulses_rev_field = app.XpulsesrevEditField;

app.amc.ver_mm_rev_field = app.YmmrevEditField;
app.amc.ver_pulses_rev_field = app.YpulsesrevEditField;

app.amc.curr_hor_field = app.XPositionmmEditField;
app.amc.curr_ver_field = app.YPositionmmEditField;

app.amc.hor_max_field = app.XMaxSizemmEditField;
app.amc.ver_max_field = app.YMaxSizemmEditField;

app.amc.isApp = true;
app.amc.Update();
end