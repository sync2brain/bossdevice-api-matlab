function issues = checkTask

projObj = currentProject;

disp('Analyzing code...');

% Identify code issues
issues = codeIssues([...
    fullfile(projObj.RootFolder,'buildUtilities'),...
    fullfile(projObj.RootFolder,'toolbox','src'),...
    fullfile(projObj.RootFolder,'toolbox','examples')]);

% Export results in SARIF format
if batchStartupOptionUsed
    issues.export('results.sarif');
end

disp('Code analysis complete.');

% Display code issues
disp(issues);

end
