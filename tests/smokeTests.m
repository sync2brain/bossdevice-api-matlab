classdef smokeTests < matlab.unittest.TestCase

    methods (TestClassSetup)
        % Shared setup for the entire test class
    end

    methods (TestMethodSetup)
        % Setup for each test
    end

    methods (Test)
        % Test methods

        function noFirmware(testCase)
            testCase.verifyError(@() bossdevice, 'bossapi:noMLDATX');
        end
    end

    methods (Test, TestTags = {'noHW'})
        % Test methods

        function noBossdevice(testCase)
            bd = bossdevice;
            testCase.verifyFalse(bd.isConnected);
        end
    end

end
