function buildDoc

% Get current project object
projObj = currentProject;

outputFolder = fullfile(projObj.RootFolder,'toolbox','html');

% Export documentation to HTML before packaging toolbox
bossapi.exportToHTML(fullfile(projObj.RootFolder,'docSource'),outputFolder);

% Build searchable database
builddocsearchdb(outputFolder);

end