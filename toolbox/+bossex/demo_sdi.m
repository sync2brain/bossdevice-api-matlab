% demo_sdi
% this script demonstrates the use of Simulink Data Inspector to visualize data streamed from the bossdevice

bd = bossdevice;

if bd.isRunning
    bd.stop;
end
bd.removeAllInstruments;

inst = slrealtime.Instrument;
inst.addSignal("eeg");
inst.addSignal("con");
bd.addInstrument(inst);

bd.start;
pause(5);
bd.stop;

Simulink.sdi.view;
Simulink.sdi.setSubPlotLayout(2,1);

runObj = Simulink.sdi.Run.getLatest;
eegSig = runObj.getSignalsByName("eeg");
eegSig.expand;
conSig = runObj.getSignalsByName("con");
conSig.expand;

plotOnSubPlot(eegSig.Children(1),1,1,true);
plotOnSubPlot(conSig.Children(1),2,1,true);