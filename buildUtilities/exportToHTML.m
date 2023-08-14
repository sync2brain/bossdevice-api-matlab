function exportToHTML(inputFolder,outputFolder)
%EXPORTTOHTML Export files to HTML

arguments
    inputFolder {mustBeFolder}
    outputFolder {mustBeFolder}
end

docFiles = findAllFiles(inputFolder);

fprintf('Exporting files to HTML format...\n');
for i = 1:numel(docFiles)
    fprintf('Exporting file %s (%i/%i)...\n',docFiles(i).name,i,numel(docFiles));
    export(fullfile(docFiles(i).folder,docFiles(i).name),outputFolder,'Format','html');
end
fprintf('Export completed.\n');

% Build searchable database
builddocsearchdb(outputFolder);

end

function files = findAllFiles(folder)

files = dir(fullfile(folder,'**/*.mlx'));

end