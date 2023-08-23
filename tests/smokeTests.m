classdef smokeTests < matlab.unittest.TestCase

    properties (Constant)
        firmwarePath = fullfile('C:\bossdevice_firmware',matlabRelease.Release)
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
        function clearBossdeviceObj(testCase)
            if ~isempty(testCase.bd) && testCase.bd.isConnected
                testCase.bd.stop;
                testCase.bd.targetObject.disconnect;
            end
        end
    end

    methods (Test, TestTags = {'noHW'})
        % Test methods that do not require bossdevice or any target connected
        function noFirmware(testCase)
            testCase.verifyWarning(@() bossdevice, 'bossapi:noMLDATX');
        end

        function noBossdevice(testCase)
            import matlab.unittest.fixtures.PathFixture
            testCase.applyFixture(PathFixture(testCase.firmwarePath));
            testCase.bd = bossdevice;
            testCase.verifyFalse(testCase.bd.isConnected);
        end
    end

    methods (Test, TestTags = {'bdConnected'})
        % Test methods with bossdevice connected and reachable from the host PC
        function bdInitialization(testCase)
            import matlab.unittest.fixtures.PathFixture
            testCase.applyFixture(PathFixture(testCase.firmwarePath));
            testCase.bd = bossdevice;
            testCase.bd.initialize;
            testCase.verifyTrue(testCase.bd.isConnected);
            testCase.verifyTrue(testCase.bd.isInitialized);
            testCase.verifyFalse(testCase.bd.isRunning);
            testCase.verifyFalse(testCase.bd.isArmed);
            testCase.verifyFalse(testCase.bd.isGeneratorRunning);
        end

        function bdShortRun(testCase)
            import matlab.unittest.fixtures.PathFixture
            testCase.applyFixture(PathFixture(testCase.firmwarePath));
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
