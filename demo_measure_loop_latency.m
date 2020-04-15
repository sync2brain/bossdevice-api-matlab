%% Summary
% This demo script uses BOSS Device to Measure loop latency between the Amplifier and BOSS Device Signals
% Resources % Requirements:  1) BOSS Device Switched On
%                            2) BOSS Device Open Source MATLAB API
%                            3) Biosignal Amplifier streaming any number of channels
% Press Ctrl+C on MATLAB command line to stop the script anytime

%% Initializing BOSS Device 
bd = bossdevice;

%% Configuring Scope
sc = addscope(bd.tg, 'host', 255);

mrk_signal_id = getsignalid(bd.tg, 'UDP/raw_mrk') + int32([0 1 2]);

addsignal(sc, mrk_signal_id);
sc.NumSamples = 100;
sc.NumPrePostSamples = -50;
sc.Decimation = 1;
sc.TriggerMode = 'Signal';
sc.TriggerSignal = getsignalid(bd.tg, 'gen_running');
sc.TriggerLevel = 0.5;
sc.TriggerSlope = 'Rising';

%% Generating Trigger

fprintf('\nTesting... ')
start(sc);
pause(0.1); % give the scope time to pre-aquire
assert(strcmp(sc.Status, 'Ready for being Triggered'));

s = [0, 1, 0];
s(1000,3) = 0; % fill with zeros (TODO: this should be done in the API)
bd.generator_sequence = s;

bd.manualTrigger;

pause(0.1)
assert(strcmp(sc.Status, 'Finished'))

fprintf('loop delay is %2.1f ms\n', (find(sc.Data(:,1), 1)-50)/5)