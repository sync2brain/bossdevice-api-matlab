%% Summary
% This demo script uses BOSS Device to estimate Phase Prediction Error
% Resources:   1) BOSS Device Switched On
%              2) BOSS Device Open Source MATLAB API
%              3) Signal Generator with 11Hz Frequency

% Press Ctrl+C on MATLAB command line to stop the script anytime

%% Circular statistics functions
ang_diff = @(x, y) angle(exp(1i*x)./exp(1i*y));
ang_var = @(x) 1-abs(mean(exp(1i*x)));
%ang_var2dev = @(v) sqrt(2*v); % circstat preferred formula uses angular deviation (bounded from 0 to sqrt(2)) which is sqrt(2*(1-r))
ang_var2dev = @(v) sqrt(-2*log(1-v)); % formula for circular standard deviation is sqrt(-2*ln(r))

%%  Initializing BOSS Device API
bb = bossdevice;
bd.eeg_channels = 1;
bd.aux_channels = 1;
bd.spatial_filter_weights = 1;

bd.alpha.offset_samples = 5; %this depends on the loop-delay

%% Setting Filters to BOSS Device
% this allows calibrating the oscillation analysis to an individual peak frequency
bd.alpha.bpf_fir_coeffs = firls(70, [0 6 9 13 16 (500/2)]/(500/2), [0 0 1 1 0 0], [1 1 1]);
%fvtool(bd.alpha.bpf_fir_coeffs, 'Fs', 500) % visualize filter

%% Configuring a scope to acquire data
sc = addscope(bd.tg, 'host', 101);
addsignal(sc, getsignalid(bd.tg, 'SPF/Matrix Multiply')); % this signals goes into the oscillation analysis
addsignal(sc, getsignalid(bd.tg, 'OSC/alpha/IP')); % instantaneous phase estimate for alpha

sc.NumSamples = 10 * 5000;
sc.Decimation = 1;

fprintf('\nAcquiring data ...'), start(sc);
while(strcmp(sc.Status, 'Acquiring')), fprintf('.'), pause(1), end
fprintf(' done')
            
data = sc.Data(:,1);
ip_estimate_causal = sc.Data(:,end);
fs = 1/mean(diff(sc.Time));

fprintf('\nDetermining phase using standard non-causal methods ...')
% demean
data = data - mean(data);
% zero phase band-pass filter
D = designfilt('bandpassfir', 'FilterOrder', round(1*fs), 'CutoffFrequency1', 9, 'CutoffFrequency2', 13, 'SampleRate', fs);
data = filtfilt(D, data); %demean

ip_estimate_noncausal = angle(hilbert(data));
phase_error = ang_diff(ip_estimate_noncausal, ip_estimate_causal);

fprintf('\n')

%% Visualize           
figure
ax1 = subplot(2,2,1);
plot(sc.Time-sc.Time(1), [sc.Data(:,1) data])
ax2 = subplot(2,2,2);
plot(sc.Time-sc.Time(1), [ip_estimate_causal ip_estimate_noncausal])
linkaxes([ax1 ax2], 'x')
subplot(2,2,4,polaraxes);
polarhistogram(phase_error, 'Normalization', 'probability', 'BinWidth', pi/36);
title(sprintf('circular standard deviation = %.1f°', rad2deg(ang_var2dev(ang_var(phase_error)))))
            
% remove the scope
remscope(bd.tg, 101)