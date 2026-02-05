classdef basicTests < matlab.unittest.TestCase

    properties (Constant)
        bd = bossdevice
    end

    methods (TestClassSetup)
        function disconnectBossdevice(testCase)
            if testCase.bd.isConnected
                testCase.bd.delete;
            end
        end
    end

    methods (Test, TestTags = {'noHW'})
        % Test methods that do not require bossdevice or any target connected
        function noBossdevice(testCase)
            testCase.verifyFalse(testCase.bd.isConnected);
        end

        function initializeError(testCase)
            testCase.verifyError(@() testCase.bd.manualTrigger, 'bossdeviceapi:appNotRunning');
        end

        function startRecordingError(testCase)
            testCase.verifyError(@() testCase.bd.startRecording, 'slrealtime:target:notConnectedError');
        end
    end

end