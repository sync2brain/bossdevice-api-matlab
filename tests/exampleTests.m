classdef exampleTests < matlab.unittest.TestCase
    %EXAMPLETESTS Execute all shipping examples

    properties (Constant)
        firmwarePath = fullfile(getenv('firmwareSharePath'),matlabRelease.Release)
    end

    properties (TestParameter)
        exName = {'demo_jittered_open_loop_stimulation'}
    end

    properties
        bd bossdevice
    end

    methods (TestClassSetup)
        function setupBossdevice(testCase)
            import matlab.unittest.fixtures.PathFixture
            if isfolder(testCase.firmwarePath)
                testCase.applyFixture(PathFixture(testCase.firmwarePath));
            end
            testCase.bd = bossdevice;
            testCase.bd.targetObject.update;
        end
    end

    methods (TestClassTeardown)
        function rebootTarget(testCase)
            disp('Rebooting bossdevice to teardown test class.');
            testCase.bd.targetObject.reboot;
            pause(10);
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