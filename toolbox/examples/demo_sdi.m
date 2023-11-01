% demo_sdi
% this script demonstrates the use of Simulink Data Inspector to visualize data streamed from the bossdevice

% Initialize bossdevice object
bd = bossdevice;

% Stop application if it was alrady running
if bd.isRunning
    bd.stop;
end

% Prepare instrument object with signals to stream
inst = slrealtime.Instrument;
inst.addSignal("eeg");
inst.addSignal("con");
bd.addInstrument(inst);

% Run real-time simulation for 5s
bd.start;
pause(5);
bd.stop;

% Clear all instrumentation objects
bd.removeAllInstruments;

% Open Simulation Data Inspect (SDI) and prepare plot layout
Simulink.sdi.view;
Simulink.sdi.clearAllSubPlots;
Simulink.sdi.setSubPlotLayout(2,1);

% Get latest SDI run
runObj = Simulink.sdi.Run.getLatest;

% Get signal objects and expand to conver multidimensional signals to scalar channels
eegSig = runObj.getSignalsByName("eeg");
eegSig.expand;
conSig = runObj.getSignalsByName("con");
conSig.expand;

% Plot signals in subplots
arrayfun(@(sigObj) plotOnSubPlot(sigObj,1,1,true), eegSig.Children(1:6));
plotOnSubPlot(conSig.Children(1),2,1,true);