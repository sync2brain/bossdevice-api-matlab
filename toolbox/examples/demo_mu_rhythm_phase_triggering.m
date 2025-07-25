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
bd.min_inter_trig_interval = minimium_inter_trigger_interval;
bd.configure_generator_sequence([0 0.001 1 0]); % Configuring Trigger Sequence in [Time PulseWidth Port Marker] format
bd.alpha.phase_plusminus(1) = phase_tolerance;
bd.triggers_remaining = no_of_trials;

%% Preparing an Individual Peak Frequency based Band Pass Filter for mu Alpha
bpf_fir_coeffs = firls(bandpassfilter_order, [0 (individual_peak_frequency + [-5 -2 +2 +5]) (500/2)]/(500/2), [0 0 1 1 0 0], [1 1 1] );


%% Setting Filters on BOSS Device
bd.spatial_filter_weights = spatial_filter_weights;
bd.alpha.bpf_fir_coeffs = bpf_fir_coeffs;


%% Controlling BOSS Device for mu Alpha Phase Locked Triggering

% Initialize trigger condition
temp = armNextTrigger(bd, phase);

while (bd.triggers_remaining > 0)
    % Trigger has been executed, move to the next condition
    if(bd.triggers_remaining < temp)
        bd.disarm;
        disp(['Triggered around ' (num2str(rad2deg(bd.alpha.phase_target(1)))) ' degrees Phase angle.']);

        % Prepare next trigger condition
        temp = armNextTrigger(bd, phase);
    else
        % Wait
        pause(0.01);
    end
end

%% End
bd.stop;
disp ('Protocol has been completed');


%%
function temp = armNextTrigger(bd, phase)
temp = bd.triggers_remaining;
bd.alpha.phase_target(1) = phase(randi(1:numel(phase), 1));
bd.arm;
end