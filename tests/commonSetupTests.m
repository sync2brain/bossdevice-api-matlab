classdef commonSetupTests < matlab.unittest.TestCase

    properties
        bd bossdevice
        sgPath
        isSGinstalled
    end

    methods (TestClassSetup)
        function setupBossdevice(testCase)
            [testCase.isSGinstalled, testCase.sgPath] = bossapi.sg.isSpeedgoatBlocksetInstalled;
            if testCase.isSGinstalled
                % If local installation of Speedgoat blockset is present, update toolbox dependencies and work with them
                bossapi.sg.removeSpeedgoatBlocksetFromPath(testCase.sgPath);
            end

            % Update target and wait until it has rebooted
            testCase.bd = bossdevice;
            testCase.bd.targetObject.update;
            bossapi.waitTargetReady(testCase.bd.targetObject);
            
            % Wait additional seconds since the target may respond ping but not be ready yet
            pause(10);

            % Set Ethernet IP in secondary interface
            bossapi.setEthernetInterface(testCase.bd.targetObject,'wm1','192.168.200.255/24');
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
            if ~isempty(testCase.bd) && testCase.bd.isConnected
                disp('Rebooting bossdevice to teardown test class.');
                testCase.bd.targetObject.reboot;
                bossapi.waitTargetReady(testCase.bd.targetObject);
            end
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
    
end
