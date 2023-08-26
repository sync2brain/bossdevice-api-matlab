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
            if exist('sg_path','file')
                % If local installation of Speedgoat blockset is present, update toolbox dependencies and work with them
                disp('Remove Speedgoat local installation.');
                sg_path(0);
            end

            import matlab.unittest.fixtures.PathFixture
            if isfolder(testCase.firmwarePath)
                testCase.applyFixture(PathFixture(testCase.firmwarePath));
            end
            testCase.bd = bossdevice;
            testCase.bd.targetObject.update;
        end
    end

    methods (TestClassTeardown)
        function resetSgPath(~)
            if exist('sg_path','file')
                disp('Restore Speedgoat local installation.');
                sg_path(1);
            end
        end

        function rebootTarget(testCase)
            disp('Rebooting bossdevice to teardown test class.');
            testCase.bd.targetObject.reboot;
            pause(30);
        end
    end

    methods (TestMethodTeardown)
        function stopBossdevice(testCase)
            if testCase.bd.isConnected && testCase.bd.isRunning
                testCase.bd.stop;
                pause(5);
            end
        end
    end

    methods (Test, TestTags = {'bdConnected'})
        function runExampleScript(~, exName)
            run(exName);
        end
    end
end