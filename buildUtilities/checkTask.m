function checkTask(~)
% Identify code issues
        issues = codeIssues('../toolbox');
        assert(isempty(issues.Issues),formattedDisplayText( ...
            issues.Issues(:,["Location" "Severity" "Description"])))
end

