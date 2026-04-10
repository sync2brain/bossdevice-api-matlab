classdef triggeredBuffer < bossapi.inst.streamingAsyncBuffer
    %TRIGGEREDBUFFER Creates a buffer that stores signal data according to a trigger condition

    properties (SetAccess = immutable)
        preTrigger_ms
        postTrigger_ms

        TriggerSignal string
        TriggerCondition function_handle
    end

    properties (GetAccess = private, SetAccess = immutable, Hidden)
        RemainingPostTriggerSamplesInitial int32
    end

    properties (SetAccess = private)
        isTriggered logical
        isArmed logical

        TriggerTime {mustBePositive} % Time of occurrence of trigger event
    end

    properties (Dependent)
        isComplete logical
    end

    properties (Access = private, Hidden)
        RemainingPostTriggerSamplesCurrent int32
        Target slrealtime.Target
        Inst slrealtime.Instrument
    end

    events
        BufferComplete
    end

    methods
        function obj = triggeredBuffer(bossObj, signalName, triggerSignal, triggerCondition, preTrigger_ms, postTrigger_ms, options)
            arguments
                bossObj {mustBeA(bossObj,"bossdevice")}
                signalName {mustBeTextScalar}
                triggerSignal {mustBeTextScalar}
                triggerCondition function_handle
                preTrigger_ms {mustBeInteger,mustBeNonnegative}
                postTrigger_ms {mustBeInteger,mustBeNonnegative}
                options.ArrayIndex {mustBeVector(options.ArrayIndex,"allow-all-empties"),mustBeInteger} = [];
                options.SignalProps {mustBeText} = {};
            end

            options.AppName = bossObj.appName;
            bufOptions = struct2pairs(options);
            obj@bossapi.inst.streamingAsyncBuffer(signalName, '', (preTrigger_ms+postTrigger_ms)/1000, true, bufOptions{:});

            obj.preTrigger_ms = preTrigger_ms;
            obj.postTrigger_ms = postTrigger_ms;
            obj.RemainingPostTriggerSamplesInitial = 1+round(postTrigger_ms/obj.getSamplePeriod(bossObj.appName));
            % Check if trigger signal exists by calling its info. Errors out if signal is not found
            bossapi.inst.getInfoSignalFromMldatx(options.AppName,triggerSignal);
            obj.TriggerSignal = triggerSignal;
            obj.TriggerCondition = triggerCondition;

            obj.Target = bossObj.targetObject;

            % Reset current object once is set up
            obj.reset;

            function C=struct2pairs(S)
                % Turns a scalar struct S into a cell of string-value pairs C
                if iscell(S)
                    C=S; return
                elseif length(S)>1
                    error('Input must be a scalar struct or cell');
                end

                C=[fieldnames(S).'; struct2cell(S).'];
                C=C(:).';
            end
        end

        function isComplete = get.isComplete(obj)
            isComplete = obj.RemainingPostTriggerSamplesCurrent <= 0;
        end

        function addToInstrument(obj, instObj)
            addToInstrument@bossapi.inst.signalCallbackManager(obj, instObj);
        end

        function arm(obj)
            assert(~obj.isArmed,'Buffer is already armed.');
            obj.Inst = slrealtime.Instrument;
            obj.Inst.addSignal(obj.TriggerSignal);
            obj.addToInstrument(obj.Inst);
            obj.Inst.connectCallback(@obj.write);

            obj.Target.addInstrument(obj.Inst);
            obj.isArmed = true;
        end

        function disarm(obj)
            obj.Target.removeInstrument(obj.Inst);
            obj.isArmed = false;
        end

        function reset(obj)
            obj.isArmed = false;
            obj.isTriggered = false;
            obj.RemainingPostTriggerSamplesCurrent = obj.RemainingPostTriggerSamplesInitial;
            reset@bossapi.inst.streamingAsyncBuffer(obj);
        end

        function delete(obj)
            obj.disarm;
        end

        function out = read(obj)
            if obj.isComplete
                out = read@bossapi.inst.streamingAsyncBuffer(obj,'extractAsTimetable',true);
            elseif obj.isArmed
                if obj.isTriggered
                    error('Buffer is not complete yet. Please wait and try again.');
                else
                    error('Buffer is empty, because the trigger condition has not been detected yet.');
                end
            else
                error('Buffer is not armed. Please call its arm method first.');
            end
        end

        function write(obj, instObj, event)
            arguments
                obj
                instObj slrealtime.Instrument
                event slrealtime.internal.instrument.AcquireGroupDataEvent
            end

            if obj.Enable && ~obj.isComplete
                % Get data for trigger signal
                [triggerTime,triggerData] = getCallbackDataForSignal(instObj, event, obj.TriggerSignal);
                % Get data for buffer signal
                [signalTime,signalData] = obj.getCallbackDataForSignal(instObj, event);
                if ~ismatrix(signalData)
                    signalData = squeeze(signalData)';
                end

                % Evaluate trigger condition
                cond = feval(obj.TriggerCondition, triggerData);
                triggerIdx = find(cond==true,1,"first");

                if ~isempty(triggerIdx) && ~obj.isTriggered
                    % Trigger found in this data chunk
                    obj.TriggerTime = triggerTime(triggerIdx);
                    obj.isTriggered = true;

                    % Add all buffers pretrigger to buffer
                    obj.writeToBuffer(signalTime(1:triggerIdx-1), signalData(1:triggerIdx-1,:));

                    % Remove rows already added to buffer
                    signalTime(1:triggerIdx-1) = [];
                    signalData(1:triggerIdx-1,:) = [];
                end

                % Fill buffer with new samples depending on trigger
                numRows = numel(signalTime);
                if obj.isTriggered
                    rowsToAdd = min(obj.RemainingPostTriggerSamplesCurrent, numRows);
                    obj.writeToBuffer(signalTime(1:rowsToAdd), signalData(1:rowsToAdd,:));

                    % Update remaining post trigger samples
                    obj.RemainingPostTriggerSamplesCurrent = obj.RemainingPostTriggerSamplesCurrent - rowsToAdd;
                else
                    % Fill buffer with all new samples
                    obj.writeToBuffer(signalTime, signalData);
                end

                % Check if buffer is complete in this call
                if obj.isComplete
                    notify(obj,'BufferComplete');
                end
            end
        end

        function p = plot(obj, parentFig)
            arguments
                obj
                parentFig = uifigure
            end

            % WIP
            data = obj.read;
            p = plot(parentFig, data.Time, data.Variables);
        end
    end

    methods (Access = private)
        function writeToBuffer(obj, time, data)
            if ~isempty(data)
                if ~isempty(obj.ArrayIndex)
                    obj.Buffer.write([time, data(:, obj.ArrayIndex)]);
                else
                    obj.Buffer.write([time, data]);
                end
            end
        end
    end

    methods (Hidden)
        function peek(varargin)
            peek@bossapi.inst.streamingAsyncBuffer(varargin);
        end
    end

end
