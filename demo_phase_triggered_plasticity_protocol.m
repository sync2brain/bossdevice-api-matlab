%% Summary
% This demo script uses BOSS Device to deliver mu Phase triggered Plasticity Protocol (100 Pulses @ 100 Hz)
% Resources:   1) BOSS Device Switched On
%              2) BOSS Device Open Source MATLAB API
%              3) Biosignal Amplifier streaming atleast 5 EEG Channels
% Press Ctrl+C on MATLAB command line to stop the script anytime

%% Initializing Demo Script Variables;
no_of_trials=25;
no_of_pulses=100; 
pulse_frequency=100; %Hz
minimium_inter_trigger_interval=5; %s
phase=0; %peak
phase_tolerance=pi/40; 
individual_peak_frequency=11; % Hz
bandpassfilter_order= 75;
eeg_channels=5; %Assigning Number of channels as equivalent to Num of Channels streamed by Biosignal Processor
spatial_filter_weights=[1 -0.25 -0.25 -0.25 -0.25]'; %Column Vector of Spatial Filter Indexed wrt corrosponding Channels

time=0;
plasticity_protocol_sequence=[];

%% Initializing BOSS Device API
bd=bossdevice;
bd.sample_and_hold_period=0;
bd.calibration_mode = 'no';
bd.armed = 'no';
bd.sample_and_hold_period=0;
bd.theta.ignore; pause(0.1)
bd.beta.ignore; pause(0.1)
bd.alpha.ignore; pause(0.1)
bd.eeg_channels=eeg_channels; 

%% Preparing a Plasticity Protocol Seqeuence for BOSS Device
plasticity_protocol_sequence(no_of_pulses,3)=0; %Pre filling the array 
for iPulse=1:no_of_pulses
    time=time+0.01;
    port=1;
    marker=iPulse;
    plasticity_protocol_sequence(iPulse,:)=[time port marker];
end

%% Preparing an Individual Peak Frequency based Band Pass Filter for mu Alpha
bpf_fir_coeffs = firls(bandpassfilter_order, [0 (individual_peak_frequency + [-5 -2 +2 +5]) (500/2)]/(500/2), [0 0 1 1 0 0], [1 1 1] );

%% Setting Filters on BOSS Device
bd.spatial_filter_weights=spatial_filter_weights;
bd.alpha.bpf_fir_coeffs = bpf_fir_coeffs;

%% Controlling BOSS Device for mu Alpha Phase Locked Triggering
condition_index=0;
while (condition_index <= no_of_trials)
    if(strcmp(bb.armed, 'no'))
        bb.triggers_remaining = 1;
        bb.alpha.phase_target(1) = phase;
        bb.alpha.phase_plusminus(1) = phase_tolerance;
        bb.configure_time_port_marker(plasticity_protocol_sequence)
        bb.min_inter_trig_interval = minimium_inter_trigger_interval;
        pause(0.1)
        bb.arm;
    end
    % trigger has been executed, move to the next condition
    if(bb.triggers_remaining == 0)
        condition_index = condition_index + 1;
        bb.disarm;
        disp Triggered!
        pause(minimium_inter_trigger_interval)
    end
    pause(0.01);
end

%% End
disp ('Plasticity Protocol has been completed');