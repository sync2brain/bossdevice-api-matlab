classdef commonSetupTests < matlab.unittest.TestCase

    properties
        bd bossdevice
        sgPath
        isSGinstalled
    end

    properties (Constant)
        waitTimeReboot = 30;
    end

    methods (TestClassSetup)
        function setupBossdevice(testCase)
            import matlab.unittest.constraints.Eventually
            import matlab.unittest.constraints.IsTrue

            [testCase.isSGinstalled, testCase.sgPath] = bossapi.sg.isSpeedgoatBlocksetInstalled;
            if testCase.isSGinstalled
                % If local installation of Speedgoat blockset is present, update toolbox dependencies and work with them
                bossapi.sg.removeSpeedgoatBlocksetFromPath(testCase.sgPath);
            end

            % Update target and wait until it has rebooted
            testCase.bd = bossdevice;
            testCase.bd.targetObject.update;

            testCase.assertThat(@() bossapi.pingTarget(testCase.bd.targetObject),...
                Eventually(IsTrue,"WithTimeoutOf",60),'Should wait until bossdevice has rebooted.');

            % Wait additional seconds since the target may respond ping but not be ready yet
            pause(testCase.waitTimeReboot);
        end
    end

    methods (TestClassTeardown)
        function resetSgPath(testCase)
            if testCase.isSGinstalled
                % If local installation of Speedgoat blockset is present, restore default paths
                bossapi.sg.addSpeedgoatBlocksetToPath(testCase.sgPath);
            end
        end

        function rebootTarget(testCase)
            import matlab.unittest.constraints.Eventually
            import matlab.unittest.constraints.IsTrue
            
            if ~isempty(testCase.bd) && testCase.bd.isConnected
                disp('Rebooting bossdevice to teardown test class.');
                testCase.bd.reboot;

                testCase.assertThat(@() bossapi.pingTarget(testCase.bd.targetObject),...
                    Eventually(IsTrue,"WithTimeoutOf",60),'Should wait until bossdevice has rebooted.');

                % Wait additional seconds since the target may respond ping but not be ready yet
                pause(testCase.waitTimeReboot);
            end
        end
    end

    methods (TestMethodTeardown)
        function clearBossdeviceObj(testCase)
            if ~isempty(testCase.bd) && testCase.bd.isConnected
                testCase.bd.stop;
            end
        end
    end

end
