% Get current project object
projObj = currentProject;

% Export documentation to HTML before packaging toolbox
exportToHTML(fullfile(projObj.RootFolder,'docSource'),fullfile(projObj.RootFolder,'toolbox','html')); 