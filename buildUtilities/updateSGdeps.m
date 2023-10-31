function updateSGdeps

projObj = currentProject;

[isSGinstalled, sgDefaultPath] = bossapi.sg.isSpeedgoatBlocksetInstalled;

assert(isSGinstalled,'Speedgoat dependencies not found installed in local system.');

fprintf('Updating Speedgoat dependencies in local project from %s...\n',sgDefaultPath);

% Figure out list of Speedgoat tools to copy
sgTools = dir(fullfile(sgDefaultPath,'sg_resources'));
sgTools = sgTools(~[sgTools.isdir]);

% Create dependencies folder in local toolbox
destFolder = fullfile(projObj.RootFolder,'toolbox/dependencies/sg');

% Copy Speedgoat version resources to local toolbox folder
if ~isfolder(fullfile(destFolder,matlabRelease.Release))
    mkdir(fullfile(destFolder,matlabRelease.Release));
end
for i = 1:numel(sgTools)
    copyfile(fullfile(sgTools(i).folder,sgTools(i).name),fullfile(destFolder,matlabRelease.Release));
end

% Copy common Speedgoat functions
copyfile(fullfile(sgDefaultPath,'speedgoatroot.p'),destFolder);
copyfile(fullfile(sgDefaultPath,'sg_functions','+sg'),fullfile(destFolder,'+sg'));
copyfile(fullfile(sgDefaultPath,'sg_functions','+speedgoat'),fullfile(destFolder,'+speedgoat'));
if ~isMATLABReleaseOlderThan("R2023b")
    copyfile(fullfile(sgDefaultPath,'sg_functions','sl_realtimeHardwareConfig.p'),destFolder);
end

fprintf('Speedgoat dependencies updated in toolbox.\n');

end