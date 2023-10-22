classdef smokeTests < commonSetupTests

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
