classdef exampleTests < commonSetupTests
    %EXAMPLETESTS Execute all shipping examples

    properties (TestParameter)
        exName = {'demo_jittered_open_loop_stimulation'}
    end

    methods (Test, TestTags = {'bdConnected'})
        function runExampleScript(testCase, exName)
            testCase.verifyWarningFree(@() run(exName));
        end
    end

    methods (TestMethodTeardown)
        function closeFigures(~)
            close all;
        end
    end
end