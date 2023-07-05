function setupDCAs(app)
% Assigns the properties of the GUI to the DCA_Device objects

% dca1
app.dca1.mmWaveStudioPath = app.mmWavePath;
app.dca1.textArea = app.MainTextArea;
app.dca1.app = app;
app.dca1.prepareLamp = app.DCA1PrepareLamp;

app.dca1.systemIPAddress_field = app.SystemIPAddressEditField;
app.dca1.DCA1000IPAddress_field = app.DCAIPAddressEditField;
app.dca1.configPort_field = app.ConfigPortEditField;
app.dca1.dataPort_field = app.DataPortEditField;
app.dca1.fileName_field = app.FileNameEditField;

app.dca1.isApp = true;
app.dca1.Update();

% dca2
app.dca2.mmWaveStudioPath = app.mmWavePath;
app.dca2.textArea = app.MainTextArea;
app.dca2.app = app;
app.dca2.prepareLamp = app.DCA2PrepareLamp;

app.dca2.systemIPAddress_field = app.SystemIPAddressEditField_2;
app.dca2.DCA1000IPAddress_field = app.DCAIPAddressEditField_2;
app.dca2.configPort_field = app.ConfigPortEditField_2;
app.dca2.dataPort_field = app.DataPortEditField_2;
app.dca2.fileName_field = app.FileNameEditField;

app.dca2.isApp = true;
app.dca2.Update();
end