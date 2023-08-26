function updateFirmwareDeps(shareFolder)

arguments
    shareFolder {mustBeFolder} = getenv('firmwareSharePath')
end

projObj = currentProject;

% Copy firmware in local share folder to toolbox to facilitate distribution
if ~isempty(shareFolder)
    copyfile(shareFolder,fullfile(projObj.RootFolder,'toolbox/dependencies/firmware/'));
else
    error('Share folder not found. Firmware dependencies will not be packaged in toolbox.');
end

end