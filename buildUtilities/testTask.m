function results = testTask(tags)
% Run unit tests

arguments
    tags {mustBeText} = '';
end

import matlab.unittest.TestRunner;
import matlab.unittest.TestSuite;
import matlab.unittest.Verbosity;
import matlab.unittest.plugins.XMLPlugin;
import matlab.unittest.selectors.HasTag;

projObj = currentProject;

suite = TestSuite.fromProject(projObj);
if ~isempty(tags)
    suite = suite.selectIf(HasTag(tags));
else
    disp('No tag was passed as input. All test cases will be executed.');
end

if isempty(suite)
    warning('No tests were found with tag(s) "%s" and none will be executed.',strjoin(tags,', '));
end

runner = TestRunner.withTextOutput('OutputDetail', Verbosity.Detailed);
runner.addPlugin(XMLPlugin.producingJUnitFormat(fullfile(projObj.RootFolder,'results.xml')));

results = runner.run(suite);

% CI workflows evaluate test success from Test Report
if ~batchStartupOptionUsed
    results.assertSuccess;
end

end
