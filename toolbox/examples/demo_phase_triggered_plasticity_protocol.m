%% Summary
% This demo script uses BOSS Device to deliver mu Phase triggered Plasticity Protocol (100 Pulses @ 100 Hz)
% Resources:   1) BOSS Device Switched On
%              2) BOSS Device Open Source MATLAB API
%              3) Biosignal Amplifier streaming atleast 5 EEG Channels
%              4) The stimulator is Switched On, External Trigger mode is turned on and the Stimulator is Enabled
% Press Ctrl+C on MATLAB command line to stop the script anytime

%% Initializing Demo Script Variables;
no_of_trials=5;
no_of_pulses=100;
pulse_frequency=100; %Hz
minimium_inter_trigger_interval=5; %s
phase=0; %peak
phase_tolerance=pi/40;
individual_peak_frequency=11; % Hz
bandpassfilter_order= 75;
eeg_channels=5; %Assigning Number of channels as equivalent to Num of Channels streamed by Biosignal Processor
spatial_filter_weights=[1 -0.25 -0.25 -0.25 -0.25]'; %Column Vector of Spatial Filter Indexed wrt corrosponding Channels


%% Initializing BOSS Device API
bd=bossdevice;
bd.start;
bd.disarm;
bd.sample_and_hold_seconds=0;
bd.theta.ignore;
bd.beta.ignore;
bd.alpha.ignore;
bd.num_eeg_channels=eeg_channels;


%% Preparing a Plasticity Protocol Seqeuence for BOSS Device
plasticity_protocol_sequence = zeros(no_of_pulses,4);
for iPulse=1:no_of_pulses
    plasticity_protocol_sequence(iPulse,:)=[0.01 0.001 1 iPulse]; % Configuring Trigger Sequence in [Time PulseWidth Port Marker] format
end


%% Preparing an Individual Peak Frequency based Band Pass Filter for mu Alpha
bpf_fir_coeffs = firls(bandpassfilter_order, [0 (individual_peak_frequency + [-5 -2 +2 +5]) (500/2)]/(500/2), [0 0 1 1 0 0], [1 1 1] );


%% Setting Filters on BOSS Device
bd.spatial_filter_weights=spatial_filter_weights;
bd.alpha.bpf_fir_coeffs = bpf_fir_coeffs;



%% For plasticitz, we have the same condition, multiple times, we can run everything on the device:
bd.triggers_remaining = 10;
bd.alpha.phase_target(1) = phase;
bd.alpha.phase_plusminus(1) = phase_tolerance;
bd.configure_generator_sequence(plasticity_protocol_sequence);
bd.min_inter_trig_interval = minimium_inter_trigger_interval;
bd.arm;

lastsize = 0;
while (bd.triggers_remaining > 0)
    fprintf(repmat('\b', 1, lastsize));
    lastsize = fprintf('System running, pulses remaining: %i', bd.triggers_remaining);
    pause(0.1);
end
fprintf('\nDone\n');


%% Controlling BOSS Device for mu Alpha Phase Locked Triggering
% this could be for excitability, where we have interleaved different conditions
condition_index=0;
lastsize = 0;
while (condition_index <= no_of_trials)
    fprintf(repmat('\b', 1, lastsize));
    lastsize = fprintf('Running trial %i out of %i...',condition_index,no_of_trials);
    if ~bd.isArmed
        bd.triggers_remaining = 1;
        bd.arm;
    end
    % trigger has been executed, move to the next condition
    if(bd.triggers_remaining == 0)
        condition_index = condition_index + 1;
        bd.disarm;
        fprintf('\nTriggered!\n');
        lastsize = 0;
    end
    pause(0.01);
end


%% End
disp('Plasticity Protocol has been completed');