function issues = checkTask

projObj = currentProject;

% Identify code issues
issues = codeIssues(projObj.RootFolder);

% Encode results in JSON file and export
if batchStartupOptionUsed
    jsonIssues = jsonencode(issues);
    fid = fopen(fullfile(projObj.RootFolder,'checkResults.json'),'w');
    fprintf(fid,'%s',jsonIssues);
    fclose(fid);
end

% Assert code results
% assert(isempty(issues.Issues),...
%     formattedDisplayText(issues.Issues(:,["Location" "Severity" "Description"])));

end