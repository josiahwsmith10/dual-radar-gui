function setupScanner(app)
% Assigns the properties of the GUI to the SAR_Scanner_Device object

% Add dca1 and dca2
app.scanner.dca1 = app.dca1;
app.scanner.dca2 = app.dca2;

% Add radar1 and radar2
app.scanner.radar1 = app.radar1;
app.scanner.radar2 = app.radar2;

% Add amc
app.scanner.amc = app.amc;

% Add esp
app.scanner.esp = app.esp;

% Add GUI properties
app.scanner.method = "Rectilinear";
app.scanner.textArea = app.MainTextArea;
app.scanner.app = app;

app.scanner.fileName_field = app.FileNameEditField;
app.scanner.xStep_mm_field = app.XStepSizemmEditField;
app.scanner.yStep_mm_field = app.YStepSizemmEditField;
app.scanner.numX_field = app.NumXStepsEditField;
app.scanner.numY_field = app.NumYStepsEditField;
app.scanner.xMax_mm_field = app.XMaxSizemmEditField;
app.scanner.yMax_mm_field = app.YMaxSizemmEditField;
app.scanner.DeltaX_mm_field = app.DeltaXmmEditField;
app.scanner.xOffset_mm_field = app.XOffsetmmEditField;
app.scanner.pri_ms_field = app.ScannerPeriodicitymsEditField;

app.scanner.xSize_mm_field = app.XScanSizemmEditField;
app.scanner.ySize_mm_field = app.YScanSizemmEditField;
app.scanner.scanTime_min_field = app.ScanTimeminEditField;
app.scanner.scanNotes_field = app.ScanNotesEditField;

app.scanner.isRadar1_checkbox = app.Radar1CheckBox;
app.scanner.isRadar2_checkbox = app.Radar2CheckBox;

app.scanner.isApp = true;
app.scanner.Update();
end