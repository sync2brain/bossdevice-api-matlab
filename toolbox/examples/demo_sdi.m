% demo_sdi
% this script demonstrates the use of Simulink Data Inspector to visualize data streamed from the bossdevice

% Initialize bossdevice object
bd = bossdevice;

% Stop application if it was alrady running
if bd.isRunning
    bd.stop;
end

% Run real-time simulation for 5s
bd.start;
pause(5);
bd.stop;

% Open Simulation Data Inspect (SDI) and prepare plot layout
Simulink.sdi.view;
Simulink.sdi.clearAllSubPlots;
Simulink.sdi.setSubPlotLayout(2,1);

% Get latest SDI run
runObj = Simulink.sdi.Run.getLatest;

% Get signal objects and expand to convert multidimensional signals to scalar channels
eegSig = runObj.getSignalsByName("biosignal.EEG");
eegSig.expand;
spfSig = runObj.getSignalsByName("spf_eeg");
spfSig.expand;

% Plot signals in subplots
arrayfun(@(sigObj) plotOnSubPlot(sigObj,1,1,true), eegSig.Children(1:6));
plotOnSubPlot(spfSig.Children(1),2,1,true);
