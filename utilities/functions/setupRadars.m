function setupRadars(app)
% Assigns the properties of the GUI to the TI_Radar_Device objects

% radar1
app.radar1.connectionLamp = app.Radar1ConnectionLamp;
app.radar1.configurationLamp = app.Radar1ConfigurationLamp;
app.radar1.textArea = app.MainTextArea;
app.radar1.app = app;

app.radar1.f0_GHz_field = app.StartFreqGHzEditField;
app.radar1.K_field = app.FreqSlopeMHzusEditField;
app.radar1.idleTime_us_field = app.IdleTimeusEditField;
app.radar1.txStartTime_us_field = app.TXStartTimeusEditField;
app.radar1.adcStartTime_us_field = app.ADCStartTimeusEditField;
app.radar1.adcSamples_field = app.ADCSamplesEditField;
app.radar1.fS_ksps_field = app.SampleRatekspsEditField;
app.radar1.rampEndTime_us_field = app.RampEndTimeusEditField;
app.radar1.numFrames_field = app.NoofFramesEditField;
app.radar1.numChirps_field = app.NoofChirpLoopsEditField;
app.radar1.pri_ms_field = app.PeriodicitymsEditField;
app.radar1.serialNumber_field = app.SerialNumberEditField;

app.radar1.HardwareTrigger_checkbox = app.HardwareTriggerCheckBox;

app.radar1.isApp = true;
app.radar1.Update();

% radar2
app.radar2.connectionLamp = app.Radar2ConnectionLamp;
app.radar2.configurationLamp = app.Radar2ConfigurationLamp;
app.radar2.textArea = app.MainTextArea;
app.radar2.app = app;

app.radar2.f0_GHz_field = app.StartFreqGHzEditField_2;
app.radar2.K_field = app.FreqSlopeMHzusEditField_2;
app.radar2.idleTime_us_field = app.IdleTimeusEditField_2;
app.radar2.txStartTime_us_field = app.TXStartTimeusEditField_2;
app.radar2.adcStartTime_us_field = app.ADCStartTimeusEditField_2;
app.radar2.adcSamples_field = app.ADCSamplesEditField_2;
app.radar2.fS_ksps_field = app.SampleRatekspsEditField_2;
app.radar2.rampEndTime_us_field = app.RampEndTimeusEditField_2;
app.radar2.numFrames_field = app.NoofFramesEditField_2;
app.radar2.numChirps_field = app.NoofChirpLoopsEditField_2;
app.radar2.pri_ms_field = app.PeriodicitymsEditField_2;
app.radar2.serialNumber_field = app.SerialNumberEditField_2;

app.radar2.HardwareTrigger_checkbox = app.HardwareTriggerCheckBox_2;

app.radar2.isApp = true;
app.radar2.Update();
end