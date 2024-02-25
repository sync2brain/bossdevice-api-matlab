%% Summary
% This demo script uses BOSS Device to Measure loop latency between the Amplifier and BOSS Device Signals
% Resources % Requirements:  1) BOSS Device Switched On
%                            2) BOSS Device Open Source MATLAB API
%                            3) Biosignal Amplifier streaming any number of channels
% Press Ctrl+C on MATLAB command line to stop the script anytime

%% Initializing BOSS Device 
bd = bossdevice;
bd.start;

%% Configure scopes in SDI

% Open Simulation Data Inspect (SDI) and prepare plot layout
Simulink.sdi.view;
Simulink.sdi.clearAllSubPlots;
Simulink.sdi.setSubPlotLayout(1,1);

% Get latest SDI run
runObj = Simulink.sdi.Run.getLatest;

% Get signal objects and add to subplot
mrkSig = runObj.getSignalsByName('biosignal.mrk');
mrkSig.plotOnSubPlot(1,1,true);

genRunSig = runObj.getSignalsByName('gen_running');

% Configure and add trigger
% Simulink.sdi.addTrigger(genRunSig,...
%     "Mode","Once",...
%     "Type","Edge","Polarity","Rising","Level",0.5);
Simulink.sdi.addTrigger(genRunSig,...
    "Mode","Once",...
    "Type","Edge","Level",0.5);

% Display data cursors
Simulink.sdi.setNumCursors(2);

% Cursors must be moved manually in the SDI plot for an accurate measurement of the total delay.


%% Generate trigger
s = [0, 1, 0];
s(1000,3) = 0; % fill with zeros (TODO: this should be done in the API)
bd.generator_sequence = s;

bd.manualTrigger;
