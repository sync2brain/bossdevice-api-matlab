classdef bossdevice < handle
    %BOSSDEVICE Application Programming Interface
    %   API to control the bossdevice from Matlab
    %   Requires Simulink Real-Time toolbox
    %   Supported for Matlab version 2023a

    properties
        theta
        alpha
        beta
    end

    properties (Access = protected)
        targetObject slrealtime.Target
    end

    properties (SetAccess = protected)
        firmwareFilepath
    end

    properties (Dependent)
        sample_and_hold_seconds
        spatial_filter_weights
        min_inter_trig_interval
        triggers_remaining uint16
        generator_sequence
        num_eeg_channels
        num_aux_channels
    end

    properties (SetAccess = private, Dependent)
        isConnected logical
        isInitialized logical
        isRunning logical
        isArmed logical
        isGeneratorRunning logical
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
    end

    methods
        function obj = bossdevice(targetName, ipAddress)
            %BOSSDEVICE Construct an instance of this class
            arguments
                targetName {mustBeTextScalar} = '';
                ipAddress {mustBeTextScalar} = '';
            end

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

            % Use default target if not passing any input argument
            tgs = slrealtime.Targets;
            if ~contains(tgs.getTargetNames,targetName,'IgnoreCase',true)
                tgs.addTarget(targetName);
                isTargetNew = true;
            else
                isTargetNew = false;
            end

            % Initialize and connect to the bossdevice
            obj.targetObject = slrealtime(targetName);
            if isTargetNew || ~strcmp(obj.targetObject.TargetSettings.address,ipAddress)
                obj.targetObject.TargetSettings.address = ipAddress;
                fprintf('Added new target configuration for "%s" with IP address "%s".\n',targetName,ipAddress);
            end

            % Search firmware binary and prompt user if not found in MATLAB path
            if exist([obj.appName,'.mldatx'],"file")
                obj.firmwareFilepath = obj.appName;
            elseif ~batchStartupOptionUsed
                [filename, firmwareFilepath] = uigetfile([obj.appName,'.mldatx'],...
                    'Select the firmware binary to load on the bossdevice');
                if isequal(filename,0)
                    disp('User selected Cancel.');
                    return;
                else
                    obj.firmwareFilepath = fullfile(firmwareFilepath,filename);
                end
            else
                error('bossapi:noMLDATX',[obj.appName,'.mldatx could not be found in the MATLAB path.']);
            end
        end
            
        function initialize(obj)
            % Connect to bosdevice
            obj.targetObject.connect;

            % Load firmware on the bossdevice if not loaded yet
            if ~obj.targetObject.isLoaded
                fprintf('Loading application "%s" on "%s"...\n',obj.appName,obj.targetObject.TargetSettings.name);
                obj.targetObject.load(obj.firmwareFilepath);
                fprintf('Application loaded. Ready to start.\n');
            end

            % Figure out some oscillation values
            obj.theta = bossdevice_oscillation(obj.targetObject, 'theta');
            obj.alpha = bossdevice_oscillation(obj.targetObject, 'alpha');
            obj.beta = bossdevice_oscillation(obj.targetObject, 'beta');
        end

        function start(obj)
            % Initialize bossdevice connection to enable backwards compatibility
            if ~obj.isInitialized
                obj.initialize;
            end

            % Start application on target if not running yet
            if ~obj.targetObject.isRunning
                obj.targetObject.start("ReloadOnStop",true,"StopTime",Inf);
            else
                disp('Application is already running.');
            end
        end

        function stop(obj)
            obj.targetObject.stop;
        end


        % getters and setters for dependent properties
        function duration = get.sample_and_hold_seconds(obj)
            if obj.targetObject.isConnected && obj.targetObject.isLoaded
                duration = getparam(obj.targetObject, [obj.appName,'/UDP'], 'sample_and_hold_seconds');
            end
        end

        function  set.sample_and_hold_seconds(obj, duration)
            setparam(obj.targetObject, [obj.appName,'/UDP'], 'sample_and_hold_seconds', duration);
        end


        function spatial_filter_weights = get.spatial_filter_weights(obj)
            if obj.targetObject.isConnected && obj.targetObject.isLoaded
                spatial_filter_weights = getparam(obj.targetObject, [obj.appName,'/OSC'], 'weights');
            end
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
            setparam(obj.targetObject, [obj.appName,'/OSC'], 'weights', single(weights))
        end


        function interval = get.min_inter_trig_interval(obj)
            if obj.targetObject.isConnected && obj.targetObject.isLoaded
                interval = getparam(obj.targetObject, [obj.appName,'/TRG'], 'min_inter_trig_interval');
            end
        end

        function set.min_inter_trig_interval(obj, interval)
            setparam(obj.targetObject, [obj.appName,'/TRG'], 'min_inter_trig_interval', interval);
        end

        function val = get.triggers_remaining(obj)
            if obj.targetObject.isConnected && obj.targetObject.isLoaded
                val = getsignal(obj.targetObject,[obj.appName,'/TRG/Count Down'],1);
            end
        end

        function set.triggers_remaining(obj, val)
            arguments
                obj
                val uint16
            end
            obj.targetObject.setparam([obj.appName,'/TRG'], 'countdown_reset', 0);
            obj.targetObject.setparam([obj.appName,'/TRG'], 'countdown_initialcount', val);
            obj.targetObject.setparam([obj.appName,'/TRG'], 'countdown_reset', 1);
        end

        function sequence = get.generator_sequence(obj)
            if obj.targetObject.isConnected && obj.targetObject.isLoaded
                sequence = getparam(obj.targetObject, [obj.appName,'/GEN'], 'sequence_time_port_marker');
            end
        end

        function set.generator_sequence(obj, sequence)
            setparam(obj.targetObject, [obj.appName,'/GEN'], 'sequence_time_port_marker', sequence);
        end

        function n = get.num_eeg_channels(obj)
            if obj.targetObject.isConnected && obj.targetObject.isLoaded
                n = getparam(obj.targetObject, [obj.appName,'/UDP'], 'num_eeg_channels');
            end
        end

        function set.num_eeg_channels(obj, n)
            setparam(obj.targetObject, [obj.appName,'/UDP'], 'num_eeg_channels', n);
        end


        function n = get.num_aux_channels(obj)
            if obj.targetObject.isConnected && obj.targetObject.isLoaded
                n = getparam(obj.targetObject, [obj.appName,'/UDP'], 'num_aux_channels');
            end
        end

        function set.num_aux_channels(obj, n)
            setparam(obj.targetObject, [obj.appName,'/UDP'], 'num_aux_channels', n);
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
            if obj.targetObject.isConnected && obj.targetObject.isLoaded &&...
                    (getsignal(obj.targetObject, [obj.appName,'/Unit Delay'],1))
                generator_running = true;
            else
                generator_running = false;
            end
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
                setparam(obj.targetObject, [obj.appName,'/GEN'], 'enabled', 1);
                setparam(obj.targetObject, [obj.appName,'/TRG'], 'enabled', 1);
            else
                setparam(obj.targetObject, [obj.appName,'/TRG'], 'enabled', 0);
            end
        end

        function isArmed = get.isArmed(obj)
            if obj.targetObject.isConnected && obj.targetObject.isLoaded &&...
                    (getparam(obj.targetObject, [obj.appName,'/GEN'], 'enabled') == 1 && ...
                    getparam(obj.targetObject, [obj.appName,'/TRG'], 'enabled') == 1)
                isArmed = true;
            else
                isArmed = false;
            end
        end

        function isRunning = get.isRunning(obj)
            if obj.targetObject.isConnected && obj.targetObject.isLoaded
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
                port {mustBeScalarOrEmpty}
            end

            if obj.targetObject.isRunning
                marker = port;

                sequence_time_port_marker = obj.generator_sequence;
                sequence_time_port_marker = zeros(size(sequence_time_port_marker));
                sequence_time_port_marker(1,:) = [0 port marker]; % 0 seconds after the trigger, trigger port 1 and send marker 1

                setparam(obj.targetObject, [obj.appName,'/GEN'], 'enabled', 0);
                setparam(obj.targetObject, [obj.appName,'/TRG'], 'enabled', 0);
                setparam(obj.targetObject, [obj.appName,'/GEN'], 'manualtrigger', 0);
                pause(0.1)
                obj.generator_sequence(sequence_time_port_marker);
                obj.manualTrigger;
            else
                disp('No pulse sent because app is not running yet. Start app first.');
            end
        end

    end

    methods (Access = protected)
        function manualTrigger(obj)
            setparam(obj.targetObject, [obj.appName,'/GEN'], 'enabled', 1);
            setparam(obj.targetObject, [obj.appName,'/TRG'], 'enabled', 0);

            setparam(obj.targetObject, [obj.appName,'/GEN'], 'manualtrigger', 1);
            pause(0.1);
            setparam(obj.targetObject, [obj.appName,'/GEN'], 'manualtrigger', 0);
        end
    end

end