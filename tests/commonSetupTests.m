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

            testCase.bd = bossdevice;
            testCase.bd.targetObject.update;
            testCase.waitTargetReady(testCase.bd.targetObject);
            % Wait additional seconds since the target may respond ping but not be ready yet
            pause(5);
            
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
                testCase.waitTargetReady(testCase.bd.targetObject);
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

    methods (Static, Access = protected)
        function pingSuccesful = waitTargetReady(tgObj, numAttempts)
            arguments
                tgObj slrealtime.Target
                numAttempts {mustBePositive,mustBeInteger} = 10
            end

            pingSuccesful = false;
            i = 1;
            while i <= numAttempts
                fprintf('Pinging target "%s" at "%s" (%i/%i)...\n',...
                    tgObj.TargetSettings.name, tgObj.TargetSettings.address, i, numAttempts);

                [status,~] = system(['ping ' tgObj.TargetSettings.address]);
                if status == 1
                    i = i+1;
                    % Wait 3s before next ping attempt
                    pause(3);

                elseif status == 0
                    % Ping successful
                    fprintf('Ping successful.\n');
                    pingSuccesful = true;
                    break;

                elseif i == numAttempts
                    error('Speedgoat target "%s" could not be reached in the IP address "%s".',...
                        tgObj.TargetSettings.name, tgObj.TargetSettings.address);

                else
                    error('Error executing waitTargetReady.');

                end
            end
        end
    end

end
