function [COMPortNum,COMPortName] = serialSelect(promptStr)
[err,str] = system('REG QUERY HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM');
if err
    ports = [];
else
    ports = regexp(str,'\\Device\\(?<type>[^ ]*) *REG_SZ *(?<port>COM.*?)\n','names');
    cmd = 'REG QUERY HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\ /s /f "FriendlyName" /t "REG_SZ"';
    if exist('jsystem','file')==2 %~10x faster then 'system'
        [~,str] = jsystem(cmd,'noshell');
    else
        [~,str] = system(cmd);
    end
    names = regexp(str,'FriendlyName *REG_SZ *(?<name>.*?) \((?<port>COM.*?)\)','names');
    [i,j] = ismember({ports.port},{names.port});
    [ports(i).name] = names(j(i)).name;
end

