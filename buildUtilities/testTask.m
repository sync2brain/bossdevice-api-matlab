function results = testTask(tags)
% Run unit tests

arguments
    tags string {mustBeText} = "";
end

import matlab.unittest.TestRunner;
import matlab.unittest.TestSuite;
import matlab.unittest.Verbosity;
import matlab.unittest.plugins.XMLPlugin;
import matlab.unittest.parameters.Parameter;

projObj = currentProject;

% Get list of example scripts in path
exName = {dir(fullfile(projObj.RootFolder,'toolbox/examples','**/*.m')).name}';
exName = exName(isFileOnPath(exName));
exParam = Parameter.fromData('exName',exName);

suite = TestSuite.fromProject(projObj,'ExternalParameters',exParam);
if strlength(tags)>0
    suite = suite.selectIf("Tag",tags);
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

function onPath = isFileOnPath(filename)
onPath = boolean(zeros(1,length(filename)));
for ii = 1:length(filename)
    onPath(ii) = exist(filename{ii},"file")>0;
end
end