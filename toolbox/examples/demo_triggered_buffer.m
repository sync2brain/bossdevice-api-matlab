%% Create bossdevice object and start
bd = bossdevice;
bd.start;

%% Create and arm triggered buffer object
bufObj = triggeredBuffer(bd,'spf_eeg','gen_running', @(x) x>0, 100, 1000);
bufObj.arm;

pause(5); % Pause to let the buffer pretrigger fill with some data

%% Send manual trigger and capture buffer data
bd.manualTrigger;
pause(5); % Pause must be longer than post trigger buffer length

%% When buffer is complete (check isFull or listen to BufferFull)
data = bufObj.read;
triggerTime = bufObj.TriggerTime;

%% Plot buffer data
bufObj.plot;