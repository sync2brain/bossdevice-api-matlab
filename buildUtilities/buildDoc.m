function buildDoc

% Get current project object
projObj = currentProject;

% Export documentation to HTML before packaging toolbox
bossapi.exportToHTML(fullfile(projObj.RootFolder,'docSource'),fullfile(projObj.RootFolder,'toolbox','html'));

% Build searchable database
builddocsearchdb(outputFolder);

end