%% Summary
% This demo script uses BOSS Device to deliver mu Rising or Falling Flank Phase locked Trigger outputs
% Resources:   1) BOSS Device Switched On
%              2) BOSS Device Open Source MATLAB API
%              3) Biosignal Amplifier streaming atleast 5 EEG Channels
%              4) The stimulator is Switched On, External Trigger mode is turned on and the Stimulator is Enabled
% Press Ctrl+C on MATLAB command line to stop the script anytime

%% Initializing Demo Script Variables;
no_of_trials=10;
minimium_inter_trigger_interval=5; %s
phase=[+pi/2 -pi/2]; %[falling_flank rising_flank]
phase_tolerance=pi/40; 
individual_peak_frequency=11; % Hz
bandpassfilter_order= 75;
eeg_channels=5; %Assigning Number of channels as equivalent to Num of Channels streamed by Biosignal Processor
spatial_filter_weights=[1 -0.25 -0.25 -0.25 -0.25]'; %Column Vector of Spatial Filter Indexed wrt corrosponding Channels

time=0;
plasticity_protocol_sequence=[];

%% Initializing BOSS Device API
bd=bossdevice;
bd.start;
bd.disarm;
bd.sample_and_hold_seconds=0;
bd.theta.ignore;
bd.beta.ignore;
bd.alpha.ignore;
bd.num_eeg_channels=eeg_channels; 

%% Preparing an Individual Peak Frequency based Band Pass Filter for mu Alpha
bpf_fir_coeffs = firls(bandpassfilter_order, [0 (individual_peak_frequency + [-5 -2 +2 +5]) (500/2)]/(500/2), [0 0 1 1 0 0], [1 1 1] );

%% Setting Filters on BOSS Device
bd.spatial_filter_weights=spatial_filter_weights;
bd.alpha.bpf_fir_coeffs = bpf_fir_coeffs;

%% Controlling BOSS Device for mu Alpha Phase Locked Triggering
condition_index=0;
while (condition_index <= no_of_trials)
    if ~bd.isArmed
        bd.triggers_remaining = 1;
        bd.alpha.phase_target(1) = phase(randi(1:numel(phase), 1));
        bd.alpha.phase_plusminus(1) = phase_tolerance;
        bd.configure_time_port_marker(([0, 1, 0]))
        bd.min_inter_trig_interval = minimium_inter_trigger_interval;
        pause(0.1)
        bd.arm;
    end
    % trigger has been executed, move to the next condition
    if(bd.triggers_remaining == 0)
        condition_index = condition_index + 1;
        bd.disarm;
        disp (['Triggered around ' (num2str(rad2deg(bd.alpha.phase_target(1)))) ' degrees Phase angle.'])
        pause(minimium_inter_trigger_interval)
    end
    pause(0.01);
end

%% End
disp ('Protocol has been completed');