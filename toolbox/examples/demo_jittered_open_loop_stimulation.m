%% Summary
% This demo script uses BOSS Device and 2 different approaches to generate jittered open loop stimuls
% Resources:   1) Required: BOSS Device Switch On
%             2) BOSS Device Open Source MATLAB API
%             3) The stimulator is Switched On, External Trigger mode is turned on and the Stimulator is Enabled


% Press Ctrl+C on MATLAB command line to stop the script anytime


%% Initializing Demo Script Variables;
NumberOfTrials=10; 
ITI=[4 6]; %ITI is seconds - a random number between these two values

%% Initializing BOSS Device API 
bd=bossdevice;
bd.start;

%% Approach 1 - For Loop Based Open Loop Stimulation
bd.configure_time_port_marker([0 1 1]); %Configuring Trigger Sequence in [Time Port Marker] format  
for TrialNumber=1:NumberOfTrials
    bd.manualTrigger
    disp(['Triggered Trial #' num2str(TrialNumber)])
    min_inter_trig_interval= ITI(1)+ (ITI(2)-ITI(1)).*rand(1,1); %Assigning New Random ITI for this Trial to the BOSS Device
    pause(min_inter_trig_interval) %Wait for next trial start
end
disp('Trials Completed')
%% Approach 2 - BOSS Device Sequence Generator Based Open Loop Stimulation
time_port_marker_sequence=[];
Time=0;
time_port_marker_sequence(NumberOfTrials,3)=0; %Pre filling the array 
for TrialNumber=1:NumberOfTrials
    Time=Time+ITI(1)+ (ITI(2)-ITI(1)).*rand(1,1); %Generating Sequence of Jittered ITIs for all Trials 
    Port=1; %In order to generatre trigger always on first port , use 2 for 2nd port and 3 for third port
    Marker=TrialNumber; 
    time_port_marker_sequence(TrialNumber,:)=[Time Port Marker];
end

bd.configure_time_port_marker(time_port_marker_sequence); %Assigning Pregenerated sequence to the BOSS Device 
bd.manualTrigger % Triggering the BOSS Device to start sequence TTL Output Generation
disp('Trigger Sequence Started by BOSS Device')


