function startupDRB(app)
% Startup function for the dual-radar-base-gui MATLAB application

% Create amc and set up
app.amc = AMC4030_Device();
setupAMC_DRB(app);
end