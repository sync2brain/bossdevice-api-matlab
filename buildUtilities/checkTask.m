function issues = checkTask

projObj = currentProject;

% Identify code issues
issues = codeIssues(projObj.RootFolder);
assert(isempty(issues.Issues),...
    formattedDisplayText(issues.Issues(:,["Location" "Severity" "Description"])));
end