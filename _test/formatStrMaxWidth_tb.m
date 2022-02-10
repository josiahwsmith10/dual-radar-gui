formatStrMaxWidth(x,59)

function str_new = formatStrMaxWidth(str,maxLength)
% Formats a string to create a newline every time it reaches
% the max length

numRows = ceil(strlength(str)/maxLength);

str_new = [];
str_char = char(str);
for indRow = 1:numRows
    str_new = cat(1,str_new,string(str_char((1+(indRow-1)*maxLength):min(end,indRow*maxLength))));
end
end