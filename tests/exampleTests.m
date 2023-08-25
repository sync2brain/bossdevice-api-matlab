classdef exampleTests < matlab.unittest.TestCase
    %EXAMPLETESTS Execute all shipping examples

    properties (Constant)
        firmwarePath = fullfile(getenv('firmwareSharePath'),matlabRelease.Release)
    end

    properties (TestParameter)
        exName = {'demo_mu_rhythm_phase_triggering'}
    end

    properties
        bd bossdevice
    end

    methods (TestClassSetup)
        function addFirmwarePath(testCase)
            if isfolder(testCase.firmwarePath)
                matlab.unittest.fixtures.PathFixture(testCase.firmwarePath);
            end
        end

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
        function runExampleScript(testCase, exName)
            % Need to pass the existing bd testcas object to bd as how the script expects it
            bd = testCase.bd;
            run(exName);
        end
    end
end