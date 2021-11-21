classdef bossdevice < handle
    %DBSP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        version
        tg % Real-Time target %TODO: make this private
        theta
        alpha
        beta
    end
    properties (Dependent)
        spatial_filter_weights
        triggers_remaining
        generator_sequence
        min_inter_trig_interval
        calibration_mode
        armed
        generator_running
        sample_and_hold_period
        eeg_channels
        aux_channels
    end
    
    methods
        function obj = bossdevice()
            %% Version Control
            obj.version='21-11-2021';
            %% Checking Toolboxes
            obj.checkEnvironmentToolboxes
            %% Initializing Real-Time Network
            tg = slrealtime; stop(tg);
            ip_address='192.168.7.5';
            tg.TargetSettings.address=ip_address;
            try tg.TargetSettings.name='bossdevice-RESEARCH'; catch, end
% % %             for settings = SimulinkRealTime.getTargetSettings('-all');
% % %                 if(strcmp(settings.Name, 'bossdevice')), continue, end
% % %                 if(strcmp(settings.TcpIpTargetAddress, ip_address)),
% % %                     warning(['Removing target ' settings.Name ' with duplicate ip address ' ip_address])
% % %                     SimulinkRealTime.removeTarget(settings.Name)
% % %                 end
% % %             end
% % %             env.TcpIpTargetAddress=ip_address;
% % %             env.UsBSupport='off';
% % %             env.TargetBoot = 'StandAlone';
% % %             
% % %             tg = SimulinkRealTime.target('bossdevice');
            
            %% Search for the right bossdevice.mldatx
            firmware_with_path = which('DBSP.mldatx', '-ALL');
            %error(numel(firmware_with_path)==1,'Multiple copies of firmware found in path');
            firmware_with_path = firmware_with_path{1};
            fprintf('Loading firmware from %s\n', firmware_with_path);
            tg.load(firmware_with_path(1:end-7));
            start(tg);
            
            %assert(isa(tg, 'SimulinkRealTime.target'), 'tg needs to be an SimulinkRealTime.target object')
            %assert(strcmp(tg.Connected, 'Yes'), 'Target tg needs to be connected')
            assert(strcmp(tg.ModelStatus.Application, 'DBSP'), 'Target tg needs to be loaded with DBSP firmware')
            assert(strcmp(tg.ModelStatus.State, 'RUNNING'), 'Target tg needs to be running')
            
            obj.tg = tg;
            obj.theta = bossdevice_oscillation(obj.tg, 'theta');
            obj.alpha = bossdevice_oscillation(obj.tg, 'alpha');
            obj.beta = bossdevice_oscillation(obj.tg, 'beta');
            
            %May be deprecated in model as well as here
            obj.calibration_mode = 'no';
            
            %% Redundent Untill Incorporated in Firmware
            obj.sample_and_hold_period=0;
            obj.calibration_mode = 'no';
            obj.armed = 'no';
            obj.theta.ignore; pause(0.1)
            obj.beta.ignore; pause(0.1)
            obj.alpha.ignore; pause(0.1)
        end
        
        function obj = stop(obj)
            %STOP stop any pulse generation
            %   disables event condition detector and pulse generator and
            %   diables calibration mode
            setparam(obj.tg, 'DBSP/CTL', 'calibration_mode_enabled', 0)
            setparam(obj.tg, 'DBSP/CTL', 'gen_enabled', 0)
            setparam(obj.tg, 'DBSP/CTL', 'trg_enabled', 0)
            setparam(obj.tg, 'DBSP/CTL', 'gen_timeout_trigger_enabled', 0)
            setparam(obj.tg, 'DBSP/CTL', 'gen_manual_trigger', 0)
        end
        
        function obj = arm(obj)
            obj.armed = 'yes';
        end
        
        function obj = disarm(obj)
            obj.armed = 'no';
        end
        
        function spatial_filter_weights = get.spatial_filter_weights(obj)
            spatial_filter_weights = getparam(obj.tg, 'DBSP/SPF', 'weights');
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
            setparam(obj.tg, 'DBSP/SPF', 'weights', single(weights))
        end
        
        % Think about whether we really need this function
        function set_spatial_filter_weights_by_index(obj, channel_index, w, signal_index)
            
            % check dimensions of channel_index and w assert numdim(channel_index) == 1, ... ?
            assert(size(w) == size(channel_index), 'channel indicies and weights must have the same length')
            assert(signal_index < 1 || signal_index > size(obj.spatial_filter_weights, 2), 'signal_index out of range')
            % (indices should be unique) let's not worry about this
            % indices should be whole numbers isintiger?
            assert(min(channel_index) < 1 || max(channel_index) > obj.eeg_channels, 'channel index out of range')
            
            weights = zeros(size(obj.spatial_filter_weights))
            weights(channel_index, signal_index) = w;
            
            obj.spatial_filter_weights = weights;
        end
        
        function triggers_remaining = get.triggers_remaining(obj)
            triggers_remaining = getsignal(obj.tg, 'DBSP/TRG/Counter',1);
        end
        
        function obj = set.triggers_remaining(obj, triggers)
            setparam(obj.tg, 'DBSP/CTL', 'trg_countdown_reset', 0)
            setparam(obj.tg, 'DBSP/TRG', 'countdown_initialcount', uint16(triggers))
            pause(0.1)
            setparam(obj.tg, 'DBSP/CTL', 'trg_countdown_reset', 1)
        end
        
        function sequence = get.generator_sequence(obj)
            sequence = getparam(obj.tg, 'DBSP/GEN', 'sequence_time_port_marker');
        end
        
        function obj = set.generator_sequence(obj, sequence)
            setparam(obj.tg, 'DBSP/GEN', 'sequence_time_port_marker', sequence);
        end
        
        function interval = get.min_inter_trig_interval(obj)
            interval = getparam(obj.tg, 'DBSP/TRG', 'min_inter_trig_interval');
        end
        
        function obj = set.min_inter_trig_interval(obj, interval)
            setparam(obj.tg, 'DBSP/TRG', 'min_inter_trig_interval', interval);
        end
        
        function duration = get.sample_and_hold_period(obj)
            duration = getparam(obj.tg, 'DBSP/UDP', 'sample_and_hold_period');
        end
        
        function obj = set.sample_and_hold_period(obj, duration)
            setparam(obj.tg, 'DBSP/UDP', 'sample_and_hold_period', duration);
        end
        
        function eeg_channels = get.eeg_channels(obj)
            eeg_channels = getparam(obj.tg, 'DBSP/UDP', 'eeg_channels');
        end
        
        function obj = set.eeg_channels(obj, interval)
            setparam(obj.tg, 'DBSP/UDP', 'eeg_channels', interval);
        end
        
        function aux_channels = get.aux_channels(obj)
            aux_channels = getparam(obj.tg, 'DBSP/UDP', 'aux_channels');
        end
        
        function obj = set.aux_channels(obj, duration)
            setparam(obj.tg, 'DBSP/UDP', 'aux_channels', duration);
        end
        
        % May be deprecated in future
        function calibration_mode_string = get.calibration_mode(obj)
            switch getparam(obj.tg, 'DBSP/CTL', 'calibration_mode_enabled')
                case 0
                    calibration_mode_string = 'no';
                case 1
                    calibration_mode_string = 'yes';
                otherwise
                    error('calibration_mode_enabled parameter is neither 0 nor 1')
            end
        end
        
        function obj = set.calibration_mode(obj, calibration_mode_string)
            switch calibration_mode_string
                case 'yes'
                    setparam(obj.tg, 'DBSP/CTL', 'calibration_mode_enabled', 1);
                case 'no'
                    setparam(obj.tg, 'DBSP/CTL', 'calibration_mode_enabled', 0);
                otherwise
                    error('calibration_mode must be either ''yes'' or ''no''');
            end
        end
        
        function obj = set.armed(obj, armed)
            switch armed
                case 'yes'
                    assert(strcmp(obj.calibration_mode, 'no'), 'Cannot arm target when in calibration mode')
                    assert(strcmp(obj.generator_running, 'no'), 'Cannot arm target while generator is running')
                    setparam(obj.tg, 'DBSP/CTL', 'gen_enabled', 1)
                    setparam(obj.tg, 'DBSP/CTL', 'trg_enabled', 1)
                case 'no'
                    setparam(obj.tg, 'DBSP/CTL', 'trg_enabled', 0)
                otherwise
                    error('armed must be either ''yes'' or ''no''');
            end
        end
        
        function armed = get.armed(obj)
            armed = 'no';
            if (getparam(obj.tg, 'DBSP/CTL', 'calibration_mode_enabled') == 0 && ...
                    getparam(obj.tg, 'DBSP/CTL', 'gen_enabled') == 1 && ...
                    getparam(obj.tg, 'DBSP/CTL', 'trg_enabled') == 1)
                armed = 'yes';
            end
        end
        
        function generator_running = get.generator_running(obj)
            generator_running = 'no';
            if (getsignal(obj.tg, 'DBSP/gen_running',1))
                generator_running = 'yes';
            end
        end
        
        function configure_time_port_marker(obj, sequence)
            assert(size(sequence, 1) <= size(obj.generator_sequence, 1), 'sequence exceeds maximum number of rows')
            assert(size(sequence, 2) <= 3, 'sequence cannot have more than 3 columns')
            if size(sequence, 2) == 1
                sequence = [sequence ones(size(sequence))];
            end
            if size(sequence, 1) < size(obj.generator_sequence, 1),
                sequence(size(obj.generator_sequence, 1), 3) = 0; % fill with zeros
            end
            obj.generator_sequence = sequence;
        end
        
        function manualTrigger(obj)
            setparam(obj.tg, 'DBSP/CTL', 'trg_enabled', 0)
            pause(0.5)
            setparam(obj.tg, 'DBSP/CTL', 'gen_enabled', 1)
            pause(0.1)
            setparam(obj.tg, 'DBSP/CTL', 'gen_manual_trigger', 1)
            pause(0.1)
            setparam(obj.tg, 'DBSP/CTL', 'gen_manual_trigger', 0)
        end
        
        function sendPulse(obj, varargin)
            
            if nargin > 1
                port = varargin{1};
            else
                port = 1;
            end
            
            marker = port;
            
            sequence_time_port_marker = getparam(obj.tg, 'DBSP/GEN', 'sequence_time_port_marker');
            sequence_time_port_marker = zeros(size(sequence_time_port_marker));
            sequence_time_port_marker(1,:) = [0 port marker]; % 0 seconds after the trigger, trigger port 1 and send marker 1
            
            setparam(obj.tg, 'DBSP/CTL', 'calibration_mode_enabled', 0)
            setparam(obj.tg, 'DBSP/CTL', 'gen_enabled', 0)
            setparam(obj.tg, 'DBSP/CTL', 'trg_enabled', 0)
            setparam(obj.tg, 'DBSP/CTL', 'gen_timeout_trigger_enabled', 0)
            setparam(obj.tg, 'DBSP/CTL', 'gen_manual_trigger', 0)
            pause(0.1)
            setparam(obj.tg, 'DBSP/GEN', 'sequence_time_port_marker', sequence_time_port_marker)
            obj.manualTrigger;
            
        end
        
        function checkEnvironmentToolboxes(obj)
            MandatoryToolboxes={'MATLAB','Simulink Real-Time'};
            verlist=ver;
            [InstalledToolboxes{1:length(verlist)}] = deal(verlist.Name);
            for iToolbox=1:numel(MandatoryToolboxes)
                ErrorToolboxes(iToolbox)= all(ismember(MandatoryToolboxes{1,iToolbox},InstalledToolboxes));
            end
            
        end
        
        function AuxData=mep(obj,ChannelIdx,PreTriggerPeriod,PostTriggerPeriod)
            %Inputs:
            %ChannelIdx is integer 1-8, default is 1;
            %PreTriggerPeriod is in ms, default is 100;
            %PostTriggerPeriod is in ms, default is 100;
            %Outputs:
            %1xN array of single ints containing Aux channel data @1kHz
            %sampling frequency
            try if isempty(ChannelIdx), ChannelIdx=1; end, catch, ChannelIdx=1;end
            try if isempty(PreTriggerPeriod), PreTriggerPeriod=100; end, catch,PreTriggerPeriod=100; end
            try if isempty(PostTriggerPeriod), PostTriggerPeriod=100; end, catch,PostTriggerPeriod=100; end
            if ChannelIdx>8, error('Aux channel index is invalid');end
            if ChannelIdx<1, error('Aux channel index is invalid');end
            if PreTriggerPeriod>2000, error('Aux channel period is invalid');end
            if PostTriggerPeriod>2000, error('Aux channel period is invalid');end
            try
            defaultrun=Simulink.sdi.Run.getLatest;
            sigid= getSignalsByName(defaultrun,'raw_aux');
            data=squeeze(sigid.Values.Data(1,:,end-30000:end));
            temp=find(data(9,:)>0);temp=temp(end);temp=temp+57;
            AuxData=data(ChannelIdx,temp-PreTriggerPeriod:temp+PostTriggerPeriod);
            catch
                error('The scope was not allowed to acquire complete data please wait for the post period before calling this method.');
            end
            
        end
        
        
    end
end

