function toObj = getFields(toObj,fromObj,fieldlist,suffix)
% Inputs
%   obj         -   Object to set parameters to
%   savedobj    -   Object to get parameters from
%   fieldlist   -   1D string array of parameter field names to get

if nargin == 2
    fieldlist = [];
end
if nargin == 3
    suffix = "";
end
savedfields = string(fieldnames(fromObj));
for indField = 1:length(savedfields)
    currfield = savedfields(indField);
    if max(currfield == string(fieldlist(:)))
        toObj.(currfield).(suffix) = fromObj.(currfield).(suffix);
    end
end
end