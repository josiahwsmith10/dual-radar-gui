function startupDRG(app)
% Startup function for the dual-radar-gui MATLAB application

% Load most recent settings
app = loadFields(app);

% Prompt user for guide
askOpenGuide(app);

% Create dca1 and dca2 and set up
app.dca1 = DCA_Device(1);
app.dca2 = DCA_Device(2);
setupDCAs(app);

% Create radar1 and radar2 and set up
app.radar1 = TI_Radar_Device(1);
app.radar2 = TI_Radar_Device(2);
setupRadars(app);

% Create amc and set up
app.amc = AMC4030_Device();
setupAMC(app);

% Create esp and set up
app.esp = ESP32_Device();
setupESP(app);

app.scanner = SAR_Scanner_Device();
setupScanner(app);
end