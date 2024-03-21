classdef bossdevice < handle
    %BOSSDEVICE Application Programming Interface
    %   API to control the bossdevice from Matlab
    %   Requires Simulink Real-Time toolbox

    properties
        theta bossdevice_oscillation
        alpha bossdevice_oscillation
        beta bossdevice_oscillation
    end

    properties (SetAccess = protected, Hidden)
        targetObject slrealtime.Target
        sgDepsPath
    end

    properties (SetAccess = protected)
        firmwareFilepath
    end

    properties (Dependent)
        sample_and_hold_seconds
        spatial_filter_weights
        min_inter_trig_interval
        triggers_remaining
        generator_sequence
        num_eeg_channels
        num_aux_channels
    end

    properties (SetAccess = private, Dependent)
        isConnected(1,1) logical
        isInitialized(1,1) logical
        isRunning(1,1) logical
        isArmed(1,1) logical
        isGeneratorRunning(1,1) logical
    end

    properties (Constant, Hidden)
        appName = 'mainmodel';
    end

    methods (Static)
        function clearPersonalSettings()
            s = settings;
            s.bossdeviceAPI.TargetSettings.TargetName.clearPersonalValue;
            s.bossdeviceAPI.TargetSettings.TargetIPAddress.clearPersonalValue;
        end

        function doc()
            openBossdeviceDoc;
        end
    end

    methods (Access=protected)
        function initOscillationProps(obj)
            obj.theta = bossdevice_oscillation(obj.targetObject, 'theta');
            obj.alpha = bossdevice_oscillation(obj.targetObject, 'alpha');
            obj.beta = bossdevice_oscillation(obj.targetObject, 'beta');
        end
    end

    methods
        function obj = bossdevice(targetName, ipAddress)
            %BOSSDEVICE Construct an instance of this class
            arguments
                targetName {mustBeTextScalar} = '';
                ipAddress {mustBeTextScalar} = '';
            end

            toolboxPath = fileparts(fileparts(which(mfilename)));

            % Initialize toolbox settings
            s = settings;

            % Set settings personal values
            if ~isempty(targetName)
                s.bossdeviceAPI.TargetSettings.TargetName.PersonalValue = targetName;
            end

            if ~isempty(ipAddress)
                s.bossdeviceAPI.TargetSettings.TargetIPAddress.PersonalValue = ipAddress;
            end

            % Retrieve personal value if exists otherwise get factory value
            if s.bossdeviceAPI.TargetSettings.TargetName.hasPersonalValue
                targetName = s.bossdeviceAPI.TargetSettings.TargetName.PersonalValue;
            else
                targetName = s.bossdeviceAPI.TargetSettings.TargetName.FactoryValue;
            end

            if s.bossdeviceAPI.TargetSettings.TargetIPAddress.hasPersonalValue
                ipAddress = s.bossdeviceAPI.TargetSettings.TargetIPAddress.PersonalValue;
            else
                ipAddress = s.bossdeviceAPI.TargetSettings.TargetIPAddress.FactoryValue;
            end

            % Check and enable built-in Speedgoat dependencies
            obj.sgDepsPath = fullfile(toolboxPath,'dependencies','sg');
            isSGinstalled = bossapi.sg.isSpeedgoatBlocksetInstalled;

            % Remove any possible instance of SG dependencies from the path
            sgAllPaths = strsplit(genpath(obj.sgDepsPath),';');
            cellfun(@(path) rmpath(path), sgAllPaths(ismember(sgAllPaths,strsplit(path,';'))));

            if isSGinstalled
                % Using own full installation of Speedgoat I/O Blockset (for development or debugging purposes)
                fprintf('[Debug] Using own full installation of Speedgoat I/O Blockset v%s.\n',speedgoat.version);

            elseif isfolder(fullfile(obj.sgDepsPath,matlabRelease.Release))
                % MATLAB Toolbox installer adds everything to the path. We must remove first everything and
                % only add manually to the path the required folder corresponding to the current MATLAB release
                addpath(obj.sgDepsPath);
                addpath(fullfile(obj.sgDepsPath,matlabRelease.Release));
                assert(exist('updateSGtools.p','file'),...
                    sprintf('Speedgoat files not found in "%s". Please reach out to <a href="matlab:open(''bossdevice_api_support.html'')">sync2brain technical support</a>.',fullfile(obj.sgDepsPath,matlabRelease.Release)));

            else
                error('Speedgoat dependencies not found. Please reach out to <a href="matlab:open(''bossdevice_api_support.html'')">sync2brain technical support</a>.');

            end

            % Use default target if not passing any input argument
            tgs = slrealtime.Targets;
            if ~any(matches(tgs.getTargetNames,targetName,'IgnoreCase',false))
                tgs.addTarget(targetName);
                isTargetNew = true;
            else
                isTargetNew = false;
            end

            % Modify target IP settings
            obj.targetObject = slrealtime(targetName);
            if isTargetNew || ~strcmp(obj.targetObject.TargetSettings.address,ipAddress)
                obj.targetObject.TargetSettings.address = ipAddress;
                fprintf('Added new target configuration for "%s" with IP address "%s".\n',targetName,ipAddress);
            end

            % Search firmware binary and prompt user if not found in MATLAB path
            firmwareDepsPath = fullfile(toolboxPath,'dependencies','firmware',matlabRelease.Release,[obj.appName,'.mldatx']);

            % Figure out what firmware file to assign
            if isfile(firmwareDepsPath)
                obj.firmwareFilepath = firmwareDepsPath;
            elseif exist([obj.appName,'.mldatx'],"file")
                obj.firmwareFilepath = obj.appName;
            elseif ~batchStartupOptionUsed
                [filename, firmwareFilepath] = uigetfile([obj.appName,'.mldatx'],...
                    'Select the firmware binary to load on the bossdevice');
                if isequal(filename,0)
                    disp('User selected Cancel. Please select firmware mldatx file to complete bossdevice dependencies.');
                    return;
                else
                    obj.firmwareFilepath = fullfile(firmwareFilepath,filename);
                end
            else
                error('bossapi:noMLDATX',[obj.appName,'.mldatx could not be found in the MATLAB path.']);
            end

            % Initialize bossdevice if it is connected
            if obj.isConnected
                obj.initialize;
            else
                disp('Connect the bossdevice and initialize your bossdevice object to start. For example, if you are using "bd = bossdevice", run "bd.initialize".');
            end
        end

        function obj = changeBossdeviceIP(obj, targetIP, targetNetmask)
            arguments
                obj
                targetIP {mustBeTextScalar}
                targetNetmask {mustBeTextScalar} = '255.255.255.0'
            end

            % Change IP address on remote target
            res = bossapi.tg.changeRemoteTargetIP(obj.targetObject, targetIP, targetNetmask);
            if res.ExitCode~=0
                error(res.ErrorOutput);
            end

            % Reboot target to apply new settings
            obj.targetObject.reboot;

            % Apply new IP address to target settings on host PC
            obj = bossdevice(obj.targetObject.TargetSettings.name, targetIP);

            % Output message
            fprintf('The IP address "%s" has been applied to the bossdevice "%s". The device is now rebooting, please wait 30 seconds before reinitializing.\n',...
                targetIP,obj.targetObject.TargetSettings.name);
        end

        function initialize(obj)
            % Connect to bosdevice
            obj.targetObject.connect;

            % Load firmware on the bossdevice if not loaded yet
            if ~obj.targetObject.isLoaded
                % Set Ethernet IP in secondary interface
                bossapi.tg.setEthernetInterface(obj.targetObject,'wm1','192.168.200.255/24');

                fprintf('Loading application "%s" on "%s"...\n',obj.appName,obj.targetObject.TargetSettings.name);
                obj.targetObject.load(obj.firmwareFilepath);
                fprintf('Application loaded. Ready to start.\n');
            end

            % Figure out some oscillation values
            initOscillationProps(obj);
        end

        function start(obj)
            % Initialize bossdevice connection to enable backwards compatibility
            if ~obj.isInitialized
                obj.initialize;
            end

            % Start application on target if not running yet
            if ~obj.targetObject.isRunning
                obj.targetObject.start("ReloadOnStop",true,"StopTime",Inf);
                disp('Application started!');
            else
                disp('Application is already running.');
            end
        end

        function stop(obj)
            obj.targetObject.stop;
        end


        % getters and setters for dependent properties
        function duration = get.sample_and_hold_seconds(obj)
            duration = obj.getparam('UDP', 'sample_and_hold_seconds');
        end

        function set.sample_and_hold_seconds(obj, duration)
            obj.setparam('UDP', 'sample_and_hold_seconds', duration);
        end


        function spatial_filter_weights = get.spatial_filter_weights(obj)
            spatial_filter_weights = getparam(obj, 'OSC', 'weights');
        end

        function set.spatial_filter_weights(obj, weights)
            % check that the dimensions matches the number of channels
            assert(size(weights, 1) == obj.num_eeg_channels,...
                'Number of rows in weights vector (%i) must equal to number of EEG channels (%i).',size(weights, 1),obj.num_eeg_channels);
            num_rows = size(obj.spatial_filter_weights, 1);
            num_columns = size(obj.spatial_filter_weights, 2);
            % check if the number of columns does not exceed the number of parallell signals
            assert(size(weights, 2) <= num_columns,...
                'Number of columns in weights vector (%i) cannot exceed number of signal dimensions (%i).',size(weights, 2),num_columns);
            % add additional columns if necessary
            if size(weights, 2) < num_columns
                weights(1, num_columns) = 0; % fill with zeros
            end
            % expand rows to match dimensions if necessary
            if size(weights, 1) < num_rows
                weights(num_rows, 1) = 0; % fill with zeros
            end
            setparam(obj, 'OSC', 'weights', single(weights));
        end


        function interval = get.min_inter_trig_interval(obj)
            interval = getparam(obj, 'TRG', 'min_inter_trig_interval');
        end

        function set.min_inter_trig_interval(obj, interval)
            setparam(obj, 'TRG', 'min_inter_trig_interval', interval);
        end

        function val = get.triggers_remaining(obj)
            val = getsignal(obj,'TRG',2);
        end

        function set.triggers_remaining(obj, val)
            arguments
                obj
                val uint32
            end

            if obj.isRunning
                % Due to the lack of tunability of initial conditions. Revisit after R2024a
                obj.setparam('TRG', 'countdown_initialcount', val);
                obj.setparam('TRG', 'countdown_reset', 1);
                obj.setparam('TRG', 'countdown_reset', 0);
            else
                error('Remaining triggers cannot be set unless application is running. Start the bossdevice before calling this method.');
            end
        end

        function sequence = get.generator_sequence(obj)
            sequence = getparam(obj, 'GEN', 'sequence_time_port_marker');
        end

        function set.generator_sequence(obj, sequence)
            setparam(obj, 'GEN', 'sequence_time_port_marker', sequence);
        end

        function n = get.num_eeg_channels(obj)
            n = getparam(obj, 'UDP', 'num_eeg_channels');
        end

        function set.num_eeg_channels(obj, n)
            setparam(obj, 'UDP', 'num_eeg_channels', n);
        end


        function n = get.num_aux_channels(obj)
            n = getparam(obj, 'UDP', 'num_aux_channels');
        end

        function set.num_aux_channels(obj, n)
            setparam(obj, 'UDP', 'num_aux_channels', n);
        end

        function configure_time_port_marker(obj, sequence)
            numRows = size(obj.generator_sequence, 1);

            assert(size(sequence, 1) <= numRows, 'Sequence exceeds maximum number of rows.');
            assert(size(sequence, 2) <= 3, 'Sequence cannot have more than 3 columns');
            if size(sequence, 2) == 1
                sequence = [sequence ones(size(sequence))];
            end
            if size(sequence, 1) < numRows
                sequence(numRows, 3) = 0; % fill with zeros
            end
            obj.generator_sequence = sequence;
        end

        function generator_running = get.isGeneratorRunning(obj)
            generator_running = getsignal(obj, 'Rate Transition2', 1);
        end

        function obj = arm(obj)
            obj.isArmed = true;
        end

        function obj = disarm(obj)
            obj.isArmed = false;
        end

        function set.isArmed(obj, isArmed)
            if isArmed
                assert(~obj.isGeneratorRunning, 'Cannot arm target while generator is running.');
                setparam(obj, 'GEN', 'enabled', 1);
                setparam(obj, 'TRG', 'enabled', 1);
                if ~obj.isRunning
                    disp('bossdevice is armed and ready to start.');
                end
            else
                setparam(obj, 'TRG', 'enabled', 0);
            end
        end

        function isArmed = get.isArmed(obj)
            if (getparam(obj, 'GEN', 'enabled') == 1 && getparam(obj, 'TRG', 'enabled') == 1)
                isArmed = true;
            else
                isArmed = false;
            end
        end

        function isRunning = get.isRunning(obj)
            if obj.isInitialized
                isRunning = obj.targetObject.isRunning;
            else
                isRunning = false;
            end
        end

        function isConnected = get.isConnected(obj)
            isConnected = obj.targetObject.isConnected;
        end

        function isInitialized = get.isInitialized(obj)
            if obj.targetObject.isConnected && obj.targetObject.isLoaded
                isInitialized = true;
            else
                isInitialized = false;
            end
        end

        function sendPulse(obj, port)
            arguments
                obj
                port {mustBeInteger,mustBeInRange(port,1,4)}
            end

            if obj.isRunning
                marker = port;

                sequence_time_port_marker = obj.generator_sequence;
                sequence_time_port_marker = zeros(size(sequence_time_port_marker));
                sequence_time_port_marker(1,:) = [0 port marker]; % 0 seconds after the trigger, trigger port 1 and send marker 1

                setparam(obj, 'GEN', 'enabled', 0);
                setparam(obj, 'TRG', 'enabled', 0);
                setparam(obj, 'GEN', 'manualtrigger', 0);
                pause(0.1)
                obj.generator_sequence = sequence_time_port_marker;
                obj.manualTrigger;
            else
                disp('No pulse sent because app is not running yet. Start app first.');
            end
        end

        function manualTrigger(obj)
            setparam(obj, 'GEN', 'enabled', 1);
            setparam(obj, 'TRG', 'enabled', 0);

            setparam(obj, 'GEN', 'manualtrigger', 1);
            pause(0.1);
            setparam(obj, 'GEN', 'manualtrigger', 0);
        end

        function openDocumentation(obj)
            obj.doc;
        end

        function delete(obj)
            % Class destructor
            if obj.targetObject.isConnected
                obj.targetObject.stop;
                pause(2);
                obj.targetObject.disconnect;
            end
        end

        function createRecording(obj, recordingDuration)
            arguments
                obj
                recordingDuration (1,1) {mustBePositive} = 30
            end
            bossapi.inst.createRecording(recordingDuration, obj.targetObject);
        end


        %% Target object wrappers
        function addInstrument(obj, inst)
            arguments
                obj
                inst slrealtime.Instrument
            end
            obj.targetObject.addInstrument(inst);
        end

        function removeInstrument(obj, inst)
            arguments
                obj
                inst slrealtime.Instrument
            end
            obj.targetObject.removeInstrument(inst);
        end

        function removeAllInstruments(obj)
            obj.targetObject.removeAllInstruments;
        end

        function reboot(obj)
            obj.targetObject.reboot;
        end

        function setparam(obj, path, varargin)
            setparam(obj.targetObject, [obj.appName,'/bosslogic/', path], varargin{:});
        end

        function val = getparam(obj, path, varargin)
            if obj.isInitialized
                val = getparam(obj.targetObject, [obj.appName,'/bosslogic/', path], varargin{:});
            end
        end

        function val = getsignal(obj, path, varargin)
            if obj.isInitialized
                val = getsignal(obj.targetObject, [obj.appName,'/bosslogic/', path], varargin{:});
            end
        end

        function stopRecording(obj)
            obj.targetObject.stopRecording;
        end

        function startRecording(obj)
            obj.targetObject.startRecording;
        end
    end

end
