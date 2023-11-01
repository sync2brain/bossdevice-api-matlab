%% Summary
% This demo script uses BOSS Device to track Ossciliation Amplitude & Phase and Triggers Single Pulses on a defined Amplitude range and Phase
% Resources:   1) BOSS Device Switched On
%              2) BOSS Device Open Source MATLAB API
%              3) Biosignal Amplifier streaming atleast 5 EEG Channels
% Press Ctrl+C on MATLAB command line to stop the script anytime

%% Initializing Demo Script Variables;
no_of_trials=10;
minimium_inter_trigger_interval=4; %s
phase=0; %[positive]
phase_tolerance=pi/40;
amplitude_threshold=[25 75]; %[min max] in percentile
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

%% Configuring Real-Time Scopes for Amplitude Tracking

% Prepare instrument object with signals to stream
inst = slrealtime.Instrument;
inst.addSignal('osc','BusElement','alpha.ia','Decimation',5); % OSC signals run x5 faster than QLY
inst.addSignal('sig_clean');
inst.BufferData = true;
bd.addInstrument(inst);

% Prepare plots handle
hAmplitudeHistoryAxes = subplot(2,1,1);
hAmplitudeDistributionAxes = subplot(2,1,2);

%% Controlling BOSS Device for mu Alpha Phase Locked Triggering
condition_index=1;
while (condition_index <= no_of_trials)
    fprintf('Running trial %i out of %i...\n',condition_index,no_of_trials);
    pause(0.1);

    mapData = inst.getBufferedData;
    sigData = mapData.values;

    plot(hAmplitudeHistoryAxes,sigData{1}.time,sigData{1}.data(:,1));

    % remove post-stimulus data
    % amplitude_clean = sigData{1}.data(1:numel(sigData{2}.data),:);
    if length(sigData{2}.data) > length(sigData{1}.data)
        sigData{2}.data = sigData{2}.data(1:length(sigData{1}.data));
    end
    amplitude_clean = sigData{1}.data(sigData{2}.data == 1,1);

    % calculate percentiles
    amplitude_sorted = sort(amplitude_clean);
    plot(hAmplitudeDistributionAxes, amplitude_sorted)

    amp_lower = quantile(amplitude_clean, amplitude_threshold(1)/100);
    amp_upper = quantile(amplitude_clean, amplitude_threshold(2)/100);

    hold(hAmplitudeDistributionAxes, 'on')
    plot(hAmplitudeDistributionAxes, [1 length(amplitude_clean)], [amp_lower amp_upper; amp_lower amp_upper]);
    hold(hAmplitudeDistributionAxes, 'off')

    if length(amplitude_clean) > 1
        xlim(hAmplitudeDistributionAxes, [1 length(amplitude_clean)]);
    end
    if (amplitude_sorted(end) > amplitude_sorted(1))
        ylim(hAmplitudeDistributionAxes, [amplitude_sorted(1) amplitude_sorted(end)]);
    end

    % set amplitude threshold
    bd.alpha.amplitude_min(1)=amp_lower;
    bd.alpha.amplitude_max(1)=amp_upper;
    title(hAmplitudeDistributionAxes, ['Min Amplitude: ', num2str(amp_lower)]);

    if ~bd.isArmed
        bd.triggers_remaining = 1;
        bd.alpha.phase_target(1) = phase(randi(1:numel(phase), 1));
        bd.alpha.phase_plusminus(1) = phase_tolerance;
        bd.configure_time_port_marker(([0, 1, 0]))
        bd.min_inter_trig_interval = minimium_inter_trigger_interval;
        bd.arm;
    end

    % trigger has been executed, move to the next condition
    if(bd.triggers_remaining == 0)
        condition_index = condition_index + 1;
        bd.disarm;
        disp Triggered!
    end
end
disp('Experiment finished');

%% Clean up
bd.stop;
bd.removeAllInstruments;