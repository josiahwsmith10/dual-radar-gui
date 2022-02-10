function [COMPortNum,COMPortName,tf] = serialSelect(promptStr)
% Creates a dialog box for the user to select the desired serial port with
% friendly names for each of the COM Ports

devices = [];

Skey = 'HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM';
[~, list] = dos(['REG QUERY ' Skey]);
if ischar(list) && strcmp('ERROR',list(1:5))
    disp('Error: IDSerialComs - No SERIALCOMM registry entry')
    COMPortNum = [];
    COMPortName = [];
    tf = false;
    return;
end
list = strread(list,'%s','delimiter',' '); %#ok<FPARK> requires strread()
coms = 0;
for i = 1:numel(list)
    if strcmp(list{i}(1:3),'COM')
        if ~iscell(coms)
            coms = list(i);
        else
            coms{end+1} = list{i}; % Loop size is always small
        end
    end
end
key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\';
[~, vals] = dos(['REG QUERY ' key ' /s /f "FriendlyName" /t "REG_SZ"']);
if ischar(vals) && strcmp('ERROR',vals(1:5))
    disp('Error: IDSerialComs - No Enumerated USB registry entry')
    COMPortNum = [];
    COMPortName = [];
    tf = false;
    return;
end
vals = textscan(vals,'%s','delimiter','\t');
vals = cat(1,vals{:});
out = 0;
for i = 1:numel(vals)
    if strcmp(vals{i}(1:min(12,end)),'FriendlyName')
        if ~iscell(out)
            out = vals(i);
        else
            out{end+1} = vals{i}; % Loop size is always small
        end
    end
end
for i = 1:numel(coms)
    match = strfind(out,[coms{i},')']);
    ind = 0;
    for j = 1:numel(match)
        if ~isempty(match{j})
            ind = j;
        end
    end
    if ind ~= 0
        com = str2double(coms{i}(4:end));
        if com > 9
            length = 8;
        else
            length = 7;
        end
        devices{i,1} = out{ind}(27:end-length);
        devices{i,2} = com; % Loop size is always small
    end
end

COMPortNums = 0;
COMPortNames = "";
count = 1;
for d = devices'
    if ~isempty(d{1})
        COMPortNames(count) = d{1};
        COMPortNums(count) = d{2};
        count = count + 1;
    end
end

% Create the dialog box to prompt the user
[serialInd,tf] = listdlg('PromptString',promptStr,...
    'SelectionMode','single','ListSize',[300,300],...
    'ListString',"COM" + COMPortNums + " | " + COMPortNames);

COMPortName = COMPortNames(serialInd);
COMPortNum = COMPortNums(serialInd);

end