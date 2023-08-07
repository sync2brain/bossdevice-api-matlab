function plan = buildfile

import matlab.buildtool.Task

% Create a plan with no tasks
plan = buildplan;

% Create the "check" task and add it to the plan
plan("check") = Task( ...
    Description = "Identify code issues", ...
    Actions = @(~) checkTask);

% Create the "test" task and add it to the plan
plan("test") = Task( ...
    Description = "Run unit tests", ...
    Actions = @(~) testTask);

% Make the "release" task dependent on the "check" and "test" tasks
plan("package") = Task( ...
    Description = "Package toolbox", ...
    Dependencies = ["check" "test"], ...
    Actions = @(~) releaseTask);

% Set default tasks in the plan
plan.DefaultTasks = ["check" "test"];

end