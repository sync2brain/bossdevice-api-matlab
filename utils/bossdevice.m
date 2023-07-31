classdef bossdevice < handle
    %BOSSDEVICE Application Programming Interface
    %   API to control the bossdevice from Matlab
    %   Requires Simulink Real-Time toolbox
    %   Supported for Matlab version 2023a

    properties
        targetObject slrealtime.Target

        theta
        alpha
        beta
    end

    properties (Dependent)
        sample_and_hold_seconds
        spatial_filter_weights
        min_inter_trig_interval
        triggers_remaining uint16
        armed logical
        generator_sequence
        generator_running logical
        num_eeg_channels
        num_aux_channels
        isRunning
    end

    properties (Constant, Hidden)
        appName = 'mainmodel';
    end

    methods (Static)
        function obj = arm(obj)
            obj.armed = true;
        end

        function obj = disarm(obj)
            obj.armed = false;
        end
    end

    methods
        function obj = bossdevice(tg)
            %BOSSDEVICE Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                tg slrealtime.Target = slrealtime
            end
            obj.targetObject = tg;
            obj.targetObject.connect;

            if ~obj.targetObject.isLoaded
                obj.targetObject.load(obj.appName);
            end

            obj.theta = bossdevice_oscillation(obj.targetObject, 'theta');
            obj.alpha = bossdevice_oscillation(obj.targetObject, 'alpha');
            obj.beta = bossdevice_oscillation(obj.targetObject, 'beta');

            if ~obj.targetObject.isRunning
                warning('Bossdevice is not running. Use start method to start application.')
            end
        end

        function start(obj)
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
            duration = getparam(obj.targetObject, [obj.appName,'/UDP'], 'sample_and_hold_seconds');
        end

        function  set.sample_and_hold_seconds(obj, duration)
            setparam(obj.targetObject, [obj.appName,'/UDP'], 'sample_and_hold_seconds', duration);
        end


        function spatial_filter_weights = get.spatial_filter_weights(obj)
            spatial_filter_weights = getparam(obj.targetObject, [obj.appName,'/OSC'], 'weights');
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
            interval = getparam(obj.targetObject, [obj.appName,'/TRG'], 'min_inter_trig_interval');
        end

        function set.min_inter_trig_interval(obj, interval)
            setparam(obj.targetObject, [obj.appName,'/TRG'], 'min_inter_trig_interval', interval);
        end

        function val = get.triggers_remaining(obj)
            val = getsignal(obj.targetObject,[obj.appName,'/TRG/Count Down'],1);
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
            sequence = getparam(obj.targetObject, [obj.appName,'/GEN'], 'sequence_time_port_marker');
        end

        function set.generator_sequence(obj, sequence)
            setparam(obj.targetObject, [obj.appName,'/GEN'], 'sequence_time_port_marker', sequence);
        end

        function n = get.num_eeg_channels(obj)
            n = getparam(obj.targetObject, [obj.appName,'/UDP'], 'num_eeg_channels');
        end

        function set.num_eeg_channels(obj, n)
            setparam(obj.targetObject, [obj.appName,'/UDP'], 'num_eeg_channels', n);
        end


        function n = get.num_aux_channels(obj)
            n = getparam(obj.targetObject, [obj.appName,'/UDP'], 'num_aux_channels');
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

        function generator_running = get.generator_running(obj)
            if (getsignal(obj.targetObject, [obj.appName,'/gen_running'],1))
                generator_running = true;
            else
                generator_running = false;
            end
        end

        function set.armed(obj, armed)
            if armed
                assert(~obj.generator_running, 'Cannot arm target while generator is running');
                setparam(obj.targetObject, [obj.appName,'/GEN'], 'enabled', 1);
                setparam(obj.targetObject, [obj.appName,'/TRG'], 'enabled', 1);

                obj.triggers_remaining = 1;
            else
                setparam(obj.targetObject, [obj.appName,'/TRG'], 'enabled', 0);
            end
        end

        function armed = get.armed(obj)
            if (getparam(obj.targetObject, [obj.appName,'/GEN'], 'enabled') == 1 && ...
                    getparam(obj.targetObject, [obj.appName,'/TRG'], 'enabled') == 1)
                armed = true;
            else
                armed = false;
            end
        end

        function isRunning = get.isRunning(obj)
            isRunning = obj.targetObject.isRunning;
        end

    end

end