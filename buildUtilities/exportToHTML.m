function exportToHTML(inputFolder,outputFolder)
%EXPORTTOHTML Export files to HTML

arguments
    inputFolder {mustBeFolder}
    outputFolder {mustBeFolder}
end

docFiles = findAllFiles(inputFolder);

fprintf('Exporting files to %s in HTML format...\n',outputFolder);
for i = 1:numel(docFiles)
    fprintf('Exporting file %s (%i/%i)...\n',docFiles(i).name,i,numel(docFiles));
    [~, fileNameNoext] = fileparts(docFiles(i).name);
    export(fullfile(docFiles(i).folder,docFiles(i).name),...
        fullfile(outputFolder,fileNameNoext),'Format','html','Run',false);
end
fprintf('Export completed.\n');

% Build searchable database
builddocsearchdb(outputFolder);

end

function files = findAllFiles(folder)

files = dir(fullfile(folder,'**/*.mlx'));

end