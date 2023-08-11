function updateSGdeps

projObj = currentProject;
sgToolsPath = fileparts(which('updateSGtools.p','-all'));
sgToolsPath = sgToolsPath{end}; % Speedgoat I/O blockset path is always below the local project

fprintf('Updating Speedgoat dependencies in local project from %s...\n',sgToolsPath);

sgTools = dir(sgToolsPath);
sgTools = sgTools(~[sgTools.isdir]);

for i = 1:numel(sgTools)
    copyfile(fullfile(sgTools(i).folder,sgTools(i).name),...
        fullfile(projObj.RootFolder,'toolbox/dependencies/sg/'));
end

fprintf('Dependencies updated. Please commit and push changes to Git.\n');

end