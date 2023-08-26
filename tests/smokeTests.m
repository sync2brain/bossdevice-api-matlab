classdef smokeTests < matlab.unittest.TestCase

    properties (Constant)
        firmwarePath = fullfile(getenv('firmwareSharePath'),matlabRelease.Release)
    end

    properties
        bd bossdevice
        sgPath
        isSGinstalled
    end

    methods (TestClassSetup)
        function setupBossdevice(testCase)
            [testCase.isSGinstalled, testCase.sgPath] = bossapi.isSpeedgoatBlocksetInstalled;
            if testCase.isSGinstalled
                % If local installation of Speedgoat blockset is present, update toolbox dependencies and work with them
                bossapi.removeSpeedgoatBlocksetFromPath(testCase.sgPath);
            end

            testCase.bd = bossdevice;
            testCase.bd.targetObject.update;
        end

        function addFirmwarePath(testCase)
            import matlab.unittest.fixtures.PathFixture
            if isfolder(testCase.firmwarePath)
                testCase.applyFixture(PathFixture(testCase.firmwarePath));
            end
        end
    end

    methods (TestClassTeardown)
        function resetSgPath(testCase)
            if testCase.isSGinstalled
                % If local installation of Speedgoat blockset is present, restore default paths
                bossapi.addSpeedgoatBlocksetToPath(testCase.sgPath);
            end
        end

        function rebootTarget(testCase)
            disp('Rebooting bossdevice to teardown test class.');
            testCase.bd.targetObject.reboot;
            pause(30);
        end
    end

    methods (TestMethodTeardown)
        function clearBossdeviceObj(testCase)
            if ~isempty(testCase.bd) && testCase.bd.isConnected
                testCase.bd.stop;
                testCase.bd.targetObject.disconnect;
            end
        end
    end

    methods (Test, TestTags = {'noHW'})
        % Test methods that do not require bossdevice or any target connected
        function noBossdevice(testCase)
            testCase.bd = bossdevice;
            testCase.verifyFalse(testCase.bd.isConnected);
        end
    end

    methods (Test, TestTags = {'bdConnected'})
        % Test methods with bossdevice connected and reachable from the host PC
        function bdInitialization(testCase)
            testCase.bd = bossdevice;
            testCase.bd.initialize;
            testCase.verifyTrue(testCase.bd.isConnected);
            testCase.verifyTrue(testCase.bd.isInitialized);
            testCase.verifyFalse(testCase.bd.isRunning);
            testCase.verifyFalse(testCase.bd.isArmed);
            testCase.verifyFalse(testCase.bd.isGeneratorRunning);
        end

        function bdShortRun(testCase)
            testCase.bd = bossdevice;
            testCase.bd.start;
            testCase.verifyTrue(testCase.bd.isRunning);
            testCase.bd.stop;
            testCase.verifyFalse(testCase.bd.isRunning);
            % The application needs some time to be reloaded
            pause(1);
            testCase.verifyTrue(testCase.bd.isInitialized);
        end
    end

end
