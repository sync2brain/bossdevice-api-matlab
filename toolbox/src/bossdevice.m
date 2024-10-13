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

    properties (SetAccess = immutable, Hidden)
        toolboxPath
        firmwareDepsPath
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
        marker_pulse_width_sec
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

        function exportRecording()
            bossapi.inst.exportLastRunToFile();
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

            % Verify if SLRT Target Support Package is installed
            if ~batchStartupOptionUsed && isMATLABReleaseOlderThan('R2024b') % Should run always but using if due to two MATLAB bugs
                bossapi.tg.checkSLRTSupportPkg;
            end
            
            % Get bossdevice API toolbox path
            obj.toolboxPath = fileparts(fileparts(which(mfilename)));

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
            obj.sgDepsPath = fullfile(obj.toolboxPath,'dependencies','sg');
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
            obj.firmwareDepsPath = fullfile(obj.toolboxPath,'dependencies','firmware',matlabRelease.Release,[obj.appName,'.mldatx']);

            % Figure out what firmware file to assign
            if isfile(obj.firmwareDepsPath)
                obj.firmwareFilepath = obj.firmwareDepsPath;
            elseif exist([obj.appName,'.mldatx'],"file")
                obj.firmwareFilepath = which([obj.appName,'.mldatx']);
            elseif ~batchStartupOptionUsed
               obj.selectFirmware;
               disp('Please run installFirmwareOnToolbox to permanently copy the firmware file into the toolbox and skip this step.');
            else
                error('bossapi:noMLDATX',[obj.appName,'.mldatx could not be found in the MATLAB path.']);
            end

            % Initialize bossdevice if it is connected
            if obj.isConnected
                obj.initialize;
            else
                if ~batchStartupOptionUsed
                    disp('Connect the bossdevice and initialize your bossdevice object to start. For example, if you are using "bd = bossdevice", run "bd.initialize".');
                end
            end
        end

        function obj = selectFirmware(obj)
            [filename, filepath] = uigetfile([obj.appName,'.mldatx'],...
                'Select the firmware binary to load on the bossdevice');
            if isequal(filename,0)
                error('User selected Cancel. Please download the latest firmware version from <a href="https://sync2brain.com/downloads">sync2brain downloads portal</a> and select the firmware mldatx file to complete bossdevice dependencies.');
            else
                obj.firmwareFilepath = fullfile(filepath,filename);
            end
        end

        function obj = installFirmwareOnToolbox(obj)
            if isfile(obj.firmwareFilepath)
                if ~isfolder(fileparts(obj.firmwareDepsPath))
                    mkdir(fileparts(obj.firmwareDepsPath));
                end
                copyfile(obj.firmwareFilepath,fileparts(obj.firmwareDepsPath),'f');
                obj.firmwareFilepath = obj.firmwareDepsPath;
            else
                error('Firmware file is not located. Run method selectFirmware first.');
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
            num_rows = size(obj.spatial_filter_weights, 1);
            num_columns = size(obj.spatial_filter_weights, 2);
            % check that the dimensions matches the number of channels
            assert(size(weights, 1) <= num_rows,...
                'Number of rows in weights vector (%i) cannot exceed number of maximum supported EEG channels (%i).',size(weights, 1),num_rows);
            % check if the number of columns does not exceed the number of parallel signals
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
            val = getsignal(obj,{'TRG','TRG/Count Down'},1);
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
            sequence = getparam(obj, 'GEN', 'sequence_time_duration_port_marker');
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

        function val = get.marker_pulse_width_sec(obj)
            val = getparam(obj, 'GEN', 'marker_pulse_width_sec');
        end

        function set.marker_pulse_width_sec(obj, val)
            setparam(obj, 'GEN', 'marker_pulse_width_sec', val);
        end

        function obj = configure_generator_sequence(obj, sequence)
            arguments
                obj bossdevice
                sequence {mustBeNumeric}
            end
            bossapi.boss.setGenSequenceOnTarget(obj.targetObject,sequence);
        end

        function tiledObj = plot_generator_sequence(obj, sequence, figParent)
            arguments
                obj bossdevice
                sequence {mustBeNumeric} = obj.generator_sequence
                figParent = figure
            end

            % Convert generator sequence from array to table
            sequence = array2table(sequence, 'VariableNames', {'Time [s]','Pulse Width [s]','Encoded Port','Marker'});

            % Remove rows with all 0 values
            sequence(all(sequence{:,:} == 0, 2),:) = [];

            % Plot sequente in figParent
            tiledObj = bossapi.app.plotProtocolSequence(sequence, obj.marker_pulse_width_sec, figParent);
        end

        function generator_running = get.isGeneratorRunning(obj)
            generator_running = obj.getsignal('GEN',5);
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
                setparam(obj, 'GEN', 'enabled', true);
                setparam(obj, 'TRG', 'enabled', 1);
                if ~obj.isRunning
                    disp('bossdevice is armed and ready to start.');
                end
            else
                setparam(obj, 'GEN', 'enabled', false);
                setparam(obj, 'TRG', 'enabled', 0);
            end
        end

        function isArmed = get.isArmed(obj)
            if (getparam(obj, 'GEN', 'enabled') == true && getparam(obj, 'TRG', 'enabled') == 1)
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

        function sendPulse(obj, port, width, marker)
            arguments
                obj
                port {mustBeInteger,mustBeInRange(port,1,4)}
                width {mustBeScalarOrEmpty, mustBeNonnegative} = 0.001
                marker {mustBeScalarOrEmpty, mustBeInteger} = []
            end

            if obj.isRunning
                if isempty(marker)
                    marker = port;
                end

                setparam(obj, 'GEN', 'enabled', false);
                setparam(obj, 'TRG', 'enabled', 0);
                setparam(obj, 'GEN', 'manualtrigger', false);

                obj.configure_generator_sequence([0 width port marker]); % 0 seconds after the trigger and during 0.001 seconds, trigger port 1 and send marker 1

                obj.manualTrigger;
            else
                disp('No pulse sent because app is not running yet. Start app first.');
            end
        end

        function manualTrigger(obj)
            setparam(obj, 'GEN', 'enabled', true);
            setparam(obj, 'TRG', 'enabled', 0);

            setparam(obj, 'GEN', 'manualtrigger', true);
            setparam(obj, 'GEN', 'manualtrigger', false);

            disp('Triggering sequence...');

            % Block execution of manualTrigger while generator is running
            while obj.isGeneratorRunning
                pause(0.1);
            end

            disp('Sequence completed.');
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

        function restoreInstrument(obj)
            obj.removeAllInstruments;
            hInst = slrealtime.Instrument(obj.firmwareFilepath);
            hInst.addInstrumentedSignals;
            obj.addInstrument(hInst);
        end

        function [bufObj, instObj] = createAsyncBuffer(obj, signalName, bufferLen, options)
            arguments
                obj bossdevice
                signalName {mustBeTextScalar}
                bufferLen (1,1) {mustBePositive}
                options.ArrayIndex {mustBeVector,mustBeInteger} = 1;
                options.SignalProps {mustBeText} = {};
            end

            % Initializie streamingAsyncBuffer object
            bufObj = bossapi.inst.streamingAsyncBuffer(signalName,'',bufferLen,...
                'AppName',obj.appName,'ArrayIndex',options.ArrayIndex,'SignalProps',options.SignalProps);
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
            else
                val = [];
            end
        end

        function val = getsignal(obj, path, portIndex)
            arguments
                obj 
                path {mustBeText}
                portIndex {mustBeScalarOrEmpty}
            end

            if obj.isInitialized
                if ~iscell(path)
                    val = getsignal(obj.targetObject, [obj.appName,'/bosslogic/', path], portIndex);
                else
                    val = getsignal(obj.targetObject, [{[obj.appName,'/bosslogic/', path{1}]},path(2:end)], portIndex);
                end
            end
        end

        function stopRecording(obj)
            obj.targetObject.stopRecording;
            disp('Recording stopped.');
        end

        function startRecording(obj)
            if ~obj.targetObject.isRunning
                error('Target "%s" is not running yet. Start it before recording.',...
                    obj.targetObject.TargetSettings.name);
            end

            try
                obj.targetObject.stopRecording;
            catch ME
                disp(ME.message);
            end

            obj.targetObject.startRecording;
            disp('Recording started.');
        end
    end

end
