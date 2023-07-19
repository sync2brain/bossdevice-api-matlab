% demo_sdi
% this script demonstrates the use of Simulink Data Inspector to visualize
% data streamed from the bossdevice

bd = bossdevice;

if bd.targetObject.isRunning
    bd.targetObject.stop;
end
bd.targetObject.removeAllInstruments;

inst = slrealtime.Instrument;
inst.addSignal("eeg");
inst.addSignal("con");
bd.targetObject.addInstrument(inst);

bd.targetObject.start;

Simulink.sdi.view;

sdiRun = Simulink.sdi.Run.getLatest;