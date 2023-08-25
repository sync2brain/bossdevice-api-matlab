classdef exampleTests < matlab.unittest.TestCase
    %EXAMPLETESTS Execute all shipping examples

    properties (TestParameter)
        exName = {'demo_mu_rhythm_phase_triggering'}
    end

    properties
        bd bossdevice
    end

    methods (TestClassSetup)
        function updateTarget(testCase)
            testCase.bd = bossdevice;
            testCase.bd.targetObject.update;
        end
    end

    methods (TestMethodTeardown)
        function stopBossdevice(testCase)
            if testCase.bd.isConnected
                testCase.bd.stop;
            end
        end
    end

    methods (Test, TestTags = {'bdConnected'})
        function runExampleScript(~, exName)
            run(exName);
        end
    end
end