%% Summary
% This demo script uses BOSS Device to estimate Phase Prediction Error
% Resources:   1) BOSS Device Switched On
%              2) BOSS Device Open Source MATLAB API
%              3) Signal Generator with 11Hz Frequency

% Press Ctrl+C on MATLAB command line to stop the script anytime

%%  Initializing BOSS Device API
bd = bossdevice;
bd.start;

bd.num_eeg_channels = 5;
bd.num_aux_channels = 1;

bd.spatial_filter_weights = [1 -0.25 -0.25 -0.25 -0.25]';

bd.alpha.offset_samples = 3; %this depends on the loop-delay


%% Setting Filters to BOSS Device
% this allows calibrating the oscillation analysis to an individual peak frequency
% bd.alpha.bpf_fir_coeffs = firls(70, [0 6 9 13 16 (500/2)]/(500/2), [0 0 1 1 0 0], [1 1 1]);
%fvtool(bd.alpha.bpf_fir_coeffs, 'Fs', 500) % visualize filter

% Prepare instrument object with signals to stream
inst = slrealtime.Instrument;
inst.addSignal('instPhase','BusElement','alpha');
inst.addSignal('spf_eeg');
inst.BufferData = true;
bd.addInstrument(inst);

%% Retrieve signal data from bossdevice
tWait = 10;
fprintf('Waiting %is to accumulate data in buffer...\n',tWait);
pause(tWait);

% Read data from buffer
mapData = inst.getBufferedData;
sigData = mapData.values;

spf_eeg = squeeze(sigData{2}.data)';
alpha_ip = sigData{1}.data;
disp('Done.');

% Compensante offset in instantaneous predicted phase
numSamples = bd.alpha.offset_samples;
assert(numSamples >= 1);


%% Phase error using standard non-causal methods
disp('Determining phase using standard non-causal methods...');

% Prepare IIR Butterworth filter
peakFrequency = 10;
oscBPFfilter = designfilt('bandpassiir','FilterOrder',12,'HalfPowerFrequency1',peakFrequency-2,...
    'HalfPowerFrequency2',peakFrequency+2,'SampleRate',1/mode(diff(sigData{1}.time)),'DesignMethod','butter');

% Compute phase prediction error
[phaseError, meanError, meanDev] = bossapi.boss.computePhasePredictionError(oscBPFfilter,...
                        spf_eeg(1+numSamples:end-1), alpha_ip(2:end-numSamples));

disp('Done.');


%% Visualize           
polarhistogram(phaseError, 'Normalization', 'probability', 'BinWidth', pi/36);
ax = gca;
ax.ThetaZeroLocation = 'Top';
ax.ThetaLim = [-180 180];
title(sprintf('Circular mean = %.1f°\nCircular standard deviation = %.1f°', meanError, meanDev));


%% Stop and reset instrumentation
bd.stop;
