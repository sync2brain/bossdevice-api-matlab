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
        %triggers_remaining
        generator_sequence
        generator_running % read only
        num_eeg_channels
        num_aux_channels
    end

    properties (Constant, Hidden)
        appName = 'mainmodel';
    end

    methods
        function obj = bossdevice(tg)            
            %BOSSDEVICE Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                tg slrealtime.Target = slrealtime
            end
            obj.targetObject = tg;

            if ~obj.targetObject.isLoaded
                obj.targetObject.load(obj.appName);
            end

            obj.theta = bossdevice_oscillation(obj.targetObject, 'theta');
            obj.alpha = bossdevice_oscillation(obj.targetObject, 'alpha');
            obj.beta = bossdevice_oscillation(obj.targetObject, 'beta');
            
            if ~obj.targetObject.isRunning
                warning('Bossdevice is not running. Start real-time application first.')
            end
        end
        
    end

    % getters and setters for dependent properties
    methods

        function duration = get.sample_and_hold_seconds(obj)
            duration = getparam(obj.targetObject, 'mainmodel/UDP', 'sample_and_hold_seconds');
        end
        
        function obj = set.sample_and_hold_seconds(obj, duration)
            setparam(obj.targetObject, 'mainmodel/UDP', 'sample_and_hold_seconds', duration);
        end


        function spatial_filter_weights = get.spatial_filter_weights(obj)
            spatial_filter_weights = getparam(obj.targetObject, 'mainmodel/OSC', 'weights');
        end

        function obj = set.spatial_filter_weights(obj, weights)
            % check that the dimensions matches the number of channels
            assert(size(weights, 1) == obj.eeg_channels, 'number of rows in weights vector must equal number of EEG channels')
            num_rows = size(obj.spatial_filter_weights, 1);
            num_columns = size(obj.spatial_filter_weights, 2);
            % check if the number of columns does not exceed the number of parallell signals
            assert(size(weights, 2) <= num_columns, 'number of columns in weights vector cannot exceed number of signal dimensions')
            % add additional columns if necessary
            if size(weights, 2) < num_columns
                weights(1, num_columns) = 0; % fill with zeros
            end
            % expand rows to match dimensions if necessary
            if size(weights, 1) < num_rows
                weights(num_rows, 1) = 0; % fill with zeros
            end
            setparam(obj.targetObject, 'mainmodel/OSC', 'weights', single(weights))
        end


        function interval = get.min_inter_trig_interval(obj)
            interval = getparam(obj.targetObject, 'mainmodel/TRG', 'min_inter_trig_interval');
        end
        
        function obj = set.min_inter_trig_interval(obj, interval)
            setparam(obj.targetObject, 'mainmodel/TRG', 'min_inter_trig_interval', interval);
        end

        
        function sequence = get.generator_sequence(obj)
            sequence = getparam(obj.targetObject, 'mainmodel/GEN', 'sequence_time_port_marker');
        end
        
        function obj = set.generator_sequence(obj, sequence)
            setparam(obj.targetObject, 'mainmodel/GEN', 'sequence_time_port_marker', sequence);
        end

        % function generator_running = get.generator_running(obj)
        %     if (getsignal(obj.tg, 'mainmodel/gen_running', 1))
        %         generator_running = true;
        %     else
        %         generator_running = false;
        %     end
        % end

        function n = get.num_eeg_channels(obj)
            n = getparam(obj.targetObject, 'mainmodel/UDP', 'num_eeg_channels');
        end
        
        function obj = set.num_eeg_channels(obj, n)
            setparam(obj.targetObject, 'mainmodel/UDP', 'num_eeg_channels', n);
        end
     

        function n = get.num_aux_channels(obj)
            n = getparam(obj.targetObject, 'mainmodel/UDP', 'num_aux_channels');
        end
        
        function obj = set.num_aux_channels(obj, n)
            setparam(obj.targetObject, 'mainmodel/UDP', 'num_aux_channels', n);
        end

    end

end

