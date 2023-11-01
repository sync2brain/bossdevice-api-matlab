%% Summary
% This demo script uses BOSS Device to estimate Phase Prediction Error
% Resources:   1) BOSS Device Switched On
%              2) BOSS Device Open Source MATLAB API
%              3) Signal Generator with 11Hz Frequency

% Press Ctrl+C on MATLAB command line to stop the script anytime

%%  Initializing BOSS Device API
bd = bossdevice;
bd.start;

bd.num_eeg_channels = 1;
bd.num_aux_channels = 1;
bd.spatial_filter_weights = 1;

bd.alpha.offset_samples = 5; %this depends on the loop-delay


%% Setting Filters to BOSS Device
% this allows calibrating the oscillation analysis to an individual peak frequency
bd.alpha.bpf_fir_coeffs = firls(70, [0 6 9 13 16 (500/2)]/(500/2), [0 0 1 1 0 0], [1 1 1]);
%fvtool(bd.alpha.bpf_fir_coeffs, 'Fs', 500) % visualize filter


%% Configuring an instrument buffer to acquire data
instObj = slrealtime.Instrument;
instObj.addSignal('spf_sig');
instObj.addSignal('osc','BusElement','alpha.ip');
instObj.BufferData = true;

bd.addInstrument(instObj);

%% Retrieve signal data from bossdevice
disp('Waiting 10s to accumulate data in buffer...');
pause(10);
mapData = instObj.getBufferedData;
disp('Done.');

sigData = mapData.values;

spf_sigData = squeeze(sigData{1}.data);
osc_alpha_ipData = squeeze(sigData{2}.data);


%% Phase error using standard non-causal methods
disp('Determining phase using standard non-causal methods...');

% Compute sample frequency
fs = 1/mean(diff(sigData{1}.time));

% Build zero phase band-pass filter
PhaseErrorFilter = designfilt('bandpassfir', 'FilterOrder', round(fs), 'CutoffFrequency1', 9, 'CutoffFrequency2', 13, 'SampleRate', fs);

% Compute phase prediction error
[phaseError, meanError, meanDev] = bossapi.computePhasePredictionError(PhaseErrorFilter, spf_sigData(1,:), osc_alpha_ipData(1,:));

disp('Done.');


%% Visualize           
polarhistogram(phaseError, 'Normalization', 'probability', 'BinWidth', pi/36);
ax = gca;
ax.ThetaZeroLocation = 'Top';
title(sprintf('Circular mean = %.1f°\nCircular standard deviation = %.1f°', meanError, meanDev));


%% Stop and reset instrumentation
bd.stop;
bd.removeAllInstruments;