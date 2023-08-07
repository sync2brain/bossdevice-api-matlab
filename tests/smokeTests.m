classdef smokeTests < matlab.unittest.TestCase

    methods (TestClassSetup)
        % Shared setup for the entire test class
    end

    methods (TestMethodSetup)
        % Setup for each test
    end

    methods (Test, TestTags = {'github'})
        % Test methods

        function noFirmware(testCase)
            testCase.verifyError(@() bossdevice, 'bossapi:noMLDATX');
        end
    end

    methods (Test, TestTags = {'noHW'})
        % Test methods

        function noBossdevice(testCase)
            testCase.verifyError(@() bossdevice, 'slrealtime:target:connectError');
        end
    end

end