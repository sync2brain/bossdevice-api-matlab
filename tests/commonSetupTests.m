classdef commonSetupTests < matlab.unittest.TestCase

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

            fprintf('Wait 30s for target to reboot after update and set IP address in secondary interface.\n');
            pause(30);
            % Set Ethernet IP in secondary interface
            bossapi.setEthernetInterface(testCase.bd.targetObject,'wm1','192.168.200.255/24');
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

end
