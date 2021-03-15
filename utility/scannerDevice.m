classdef scannerDevice
    properties
        isConnected
        isConfigured
        COMPort
        
        connectionLamp
        configurationLamp
        textArea
    end
    methods
        function obj = scannerDevice(app)
            obj.textArea = app.MainTextArea;
            
            obj.isConnected = false;
            obj.isConfigured = false;
            obj.COMPort = 0;
        end
    end
    
    
end