function issues = checkTask

projObj = currentProject;

disp('Analyzing code...');

% Identify code issues
issues = codeIssues(projObj.RootFolder);

% Encode results in JSON file and export
if batchStartupOptionUsed
    issues.export('results');
end

disp('Code analysis complete.');

% Display code issues
formattedDisplayText(issues.Issues(:,["Location" "Severity" "Description"]));

end