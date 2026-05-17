function C=struct2pairs(S)
% Turns a scalar struct S into a cell of string-value pairs C
if iscell(S)
    C=S; return
elseif length(S)>1
    error('triggeredBuffer:wrongInputType','Input must be a scalar struct or cell');
end

C=[fieldnames(S).'; struct2cell(S).'];
C=C(:).';
end