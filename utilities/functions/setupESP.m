function setupESP(app)
% Assigns the properties of the GUI to the ESP32_Device object

app.esp.connectionLamp = app.ESP32ConnectionLamp;
app.esp.configurationLamp = app.ESP32ConfigurationLamp;
app.esp.textArea = app.MainTextArea;
app.esp.app = app;

app.esp.mm_per_rev_field = app.XmmrevEditField;
app.esp.pulses_per_rev_field = app.XpulsesrevEditField;
app.esp.xStep_mm_field = app.XStepSizemmEditField;
app.esp.xOffset_mm_field = app.XOffsetmmEditField;
app.esp.numX_field = app.NumXStepsEditField;
app.esp.numY_field = app.NumYStepsEditField;
app.esp.DeltaX_mm_field = app.DeltaXmmEditField;

app.esp.isRadar1_checkbox = app.Radar1CheckBox;
app.esp.isRadar2_checkbox = app.Radar2CheckBox;

app.esp.isApp = true;
app.esp.Update();
end