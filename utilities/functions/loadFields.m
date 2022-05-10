function app = loadFields(app)

loadFields = [
    % DCA 1 Configuration
    "SystemIPAddressEditField"
    "DCAIPAddressEditField"
    "ConfigPortEditField"
    "DataPortEditField"
    "DCA1TemplateDropDown"
    
    % DCA2 Configuration
    "SystemIPAddressEditField_2"
    "DCAIPAddressEditField_2"
    "ConfigPortEditField_2"
    "DataPortEditField_2"
    "DCA2TemplateDropDown"

    % Radar 1 Configuration
    "StartFreqGHzEditField"
    "FreqSlopeMHzusEditField"
    "IdleTimeusEditField"
    "TXStartTimeusEditField"
    "ADCStartTimeusEditField"
    "ADCSamplesEditField"
    "SampleRatekspsEditField"
    "RampEndTimeusEditField"
    "NoofFramesEditField"
    "PeriodicitymsEditField"
    "HardwareTriggerCheckBox"
    "SerialNumberEditField"

    % Radar 2 Configuration
    "StartFreqGHzEditField_2"
    "FreqSlopeMHzusEditField_2"
    "IdleTimeusEditField_2"
    "TXStartTimeusEditField_2"
    "ADCStartTimeusEditField_2"
    "ADCSamplesEditField_2"
    "SampleRatekspsEditField_2"
    "RampEndTimeusEditField_2"
    "NoofFramesEditField_2"
    "PeriodicitymsEditField_2"
    "HardwareTriggerCheckBox_2"
    "SerialNumberEditField_2"

    % AMC4030 Configuration
    "XmmrevEditField"
    "XpulsesrevEditField"
    "XSpeedmmsEditField"
    "YmmrevEditField"
    "YpulsesrevEditField"
    "YSpeedmmsEditField"
    "HomeSpeedmmsEditField"
    "HomeOffsetmmEditField"

    % Scanner Configuration
    "XMaxSizemmEditField"
    "YMaxSizemmEditField"
    "YStepSizemmEditField"
    "XStepSizemmEditField"
    "XStepSizemmEditField"
    "NumXStepsEditField"
    "NumYStepsEditField"
    "TwoDirectionScanningCheckBox"
    "DeltaXmmEditField"
    "Radar1CheckBox"
    "Radar2CheckBox"

    % App
    "isSkipGuide"

    % COM Ports
    "Radar1COMEditField"
    "Radar2COMEditField"
    "AMC4030COMEditField"
    "ESP32COMEditField"
    ];


load("saved/appSaved.mat","appSaved");

app = getFields(app,appSaved,loadFields,"Value");

end