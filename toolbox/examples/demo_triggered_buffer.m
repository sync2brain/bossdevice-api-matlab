%% Create bossdevice object and start
bd = bossdevice;
bd.start;

%% Create and arm triggered buffer object
bufObj = triggeredBuffer(bd,'spf_eeg','gen_running', @(x) x>0, 100, 1000);
bufObj.arm;

%% When buffer is complete (check isComplete or listen to BufferComplete)
data = bufObj.read;
triggerTime = bufObj.TriggerTime;

%% Plot buffer data
bufObj.plot;