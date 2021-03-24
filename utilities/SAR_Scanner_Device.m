classdef SAR_Scanner_Device < handle
    properties
        isConnected
        isConfigured
        COMPort
        
        connectionLamp
        configurationLamp
        textArea
    end
    methods
        function obj = SAR_Scanner_Device(app)
            obj.textArea = app.MainTextArea;
            
            obj.isConnected = false;
            obj.isConfigured = false;
            obj.COMPort = 0;
        end
    end
    
    
end