function updateSGdeps

projObj = currentProject;
sgToolsPath = fileparts(which('updateSGtools.p','-all'));
if isstring(sgToolsPath)
    sgToolsPath = sgToolsPath{end}; % Speedgoat I/O blockset path is always below the local project
end

fprintf('Updating Speedgoat dependencies in local project from %s...\n',sgToolsPath);

sgTools = dir(sgToolsPath);
sgTools = sgTools(~[sgTools.isdir]);

destFolder = fullfile(projObj.RootFolder,'toolbox/dependencies/sg',matlabRelease.Release);
if ~isfolder(destFolder)
    mkdir(destFolder);
end

for i = 1:numel(sgTools)
    copyfile(fullfile(sgTools(i).folder,sgTools(i).name),destFolder);
end

fprintf('Speedgoat dependencies updated in toolbox.\n');

end