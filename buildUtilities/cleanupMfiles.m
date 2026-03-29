function cleanupMfiles(rootFolder)

arguments
    rootFolder {mustBeFolder}
end

% Get a list of all .m files recursively
fileList = dir(fullfile(rootFolder, '**/*.m'));

% Delete each .m file
for i = 1:length(fileList)
    filePath = fullfile(fileList(i).folder, fileList(i).name);
    delete(filePath);
end

end