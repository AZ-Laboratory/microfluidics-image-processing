function disableWarnings()
% Disable specific MATLAB warnings
warning('off', 'MATLAB:table:RowsAddedExistingVars');
warning('off', 'images:imfindcircles:warnForSmallRadius');
warning('off','MATLAB:MKDIR:DirectoryExists')
warning('off', 'images:regmex:registrationOutBoundsTermination')
end