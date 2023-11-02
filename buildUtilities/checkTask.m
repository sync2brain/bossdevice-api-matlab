function issues = checkTask

projObj = currentProject;

disp('Analyzing code...');

% Identify code issues
issues = codeIssues([...
    fullfile(projObj.RootFolder,'buildUtilities'),...
    fullfile(projObj.RootFolder,'toolbox','src'),...
    fullfile(projObj.RootFolder,'toolbox','examples')]);

% Encode results in JSON file and export
if batchStartupOptionUsed
    issues.export('results');
end

disp('Code analysis complete.');

% Display code issues
disp(issues);

end