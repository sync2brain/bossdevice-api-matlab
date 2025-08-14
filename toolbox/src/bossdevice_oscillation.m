classdef bossdevice_oscillation
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties (Access = protected)
        targetObj slrealtime.Target
        name
    end

    properties (SetAccess = immutable)
        logObj bossapi.Logger
    end

    properties (Constant, Hidden)
        appName = 'bossdevice_main'
    end

    properties (Dependent)
        phase_target
        phase_plusminus
        amplitude_min
        amplitude_max
        lpf_fir_coeffs % Nyquist filter before decimating the signal from 5 kHz to the sample rate of the oscillation
        bpf_fir_coeffs % band pass filter coefficients
        offset_samples {mustBeInteger, mustBePositive} % Number of samples for analysis counting backwards w.r.t. to the last value
    end

    methods
        function obj = bossdevice_oscillation(targetObj, name, logObj)
            %UNTITLED Construct an instance of this class
            arguments
                targetObj slrealtime.Target
                name {mustBeMember(name,{'alpha','beta','theta'})}
                logObj bossapi.Logger
            end

            obj.targetObj = targetObj;
            obj.name = name;
            obj.logObj = logObj;

            if obj.targetObj.isConnected && obj.targetObj.isLoaded
                obj.phase_target = getparam(obj.targetObj, [obj.appName,'/EVD/' obj.name], 'phase_target');
                obj.phase_plusminus = getparam(obj.targetObj, [obj.appName,'/EVD/' obj.name], 'phase_plusminus');
                obj.amplitude_min = getparam(obj.targetObj, [obj.appName,'/EVD/' obj.name], 'amplitude_min');
                obj.amplitude_max = getparam(obj.targetObj, [obj.appName,'/EVD/' obj.name], 'amplitude_max');
            else
                obj.logObj.obj.logObj.error('bossdevice is not ready. Initialize your bossdevice object before further processing. For example, if you are using "bd = bossdevice", run "bd.initialize".');
            end
        end


        function phase_target = get.phase_target(obj)
            phase_target = getparam(obj.targetObj, [obj.appName,'/EVD/' obj.name], 'phase_target');
        end

        function obj = set.phase_target(obj, phi)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            previousValue = obj.phase_target;
            if isscalar(phi)
                newValue = previousValue;
                newValue(1) = phi;
            else
                newValue = phi;
                if ~all(size(previousValue) == size(newValue))
                    obj.logObj.warning('Wnable to set phase target, dimension mismatch');
                    return
                end
            end
            setparam(obj.targetObj, [obj.appName,'/EVD/' obj.name], 'phase_target', single(newValue));
        end


        function phase_plusminus = get.phase_plusminus(obj)
            phase_plusminus = getparam(obj.targetObj, [obj.appName,'/EVD/' obj.name], 'phase_plusminus');
        end

        function obj = set.phase_plusminus(obj, phase_plusminus)
            %set.phase_plusminus Set phase tolerance
            %   A tolerance of pi ignores the phase in generation of events
            setparam(obj.targetObj, [obj.appName,'/EVD/' obj.name], 'phase_plusminus', single(phase_plusminus));
        end


        function amplitude_min = get.amplitude_min(obj)
            amplitude_min = getparam(obj.targetObj, [obj.appName,'/EVD/' obj.name], 'amplitude_min');
        end

        function obj = set.amplitude_min(obj, amplitude_min)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            setparam(obj.targetObj, [obj.appName,'/EVD/' obj.name], 'amplitude_min', single(amplitude_min));
        end


        function amplitude_max = get.amplitude_max(obj)
            amplitude_max = getparam(obj.targetObj, [obj.appName,'/EVD/' obj.name], 'amplitude_max');
        end

        function obj = set.amplitude_max(obj, amplitude_max)
            setparam(obj.targetObj, [obj.appName,'/EVD/' obj.name], 'amplitude_max', single(amplitude_max));
        end


        function lpf_fir_coeffs = get.lpf_fir_coeffs(obj)
            lpf_fir_coeffs = getparam(obj.targetObj, [obj.appName,'/OSC/' obj.name], 'lpf_fir_coeffs');
        end

        function obj = set.lpf_fir_coeffs(obj, coeffs)
            setparam(obj.targetObj, [obj.appName,'/OSC/' obj.name], 'lpf_fir_coeffs', coeffs);
        end


        function bpf_fir_coeffs = get.bpf_fir_coeffs(obj)
            bpf_fir_coeffs = getparam(obj.targetObj, [obj.appName,'/OSC/' obj.name], 'bpf_fir_coeffs');
        end

        function obj = set.bpf_fir_coeffs(obj, coeffs)
            assert(numel(coeffs) <= numel(obj.bpf_fir_coeffs), 'number of coefficients exceeds maximum')
            if numel(coeffs) < numel(obj.bpf_fir_coeffs)
                coeffs(numel(obj.bpf_fir_coeffs)) = 0; % fill with zeros
            end
            setparam(obj.targetObj, [obj.appName,'/OSC/' obj.name], 'bpf_fir_coeffs', single(coeffs));
        end

        function offset_samples = get.offset_samples(obj)
            offset_samples = getparam(obj.targetObj, [obj.appName,'/OSC/' obj.name], 'ipe_offset_samples');
        end

        function obj = set.offset_samples(obj, weights)
            setparam(obj.targetObj, [obj.appName,'/OSC/' obj.name], 'ipe_offset_samples', weights)
        end


        function obj = ignore(obj, varargin)
            if obj.targetObj.isConnected && obj.targetObj.isLoaded
                if nargin > 1
                    % ignore a specific channel
                    i = varargin{1};
                    obj.phase_plusminus(i) = pi;
                    obj.amplitude_min(i) = 0;
                    obj.amplitude_max(i) = 1e6;
                else
                    % ignore all channels
                    obj.phase_plusminus = pi * ones(size(obj.phase_plusminus));
                    obj.amplitude_min = zeros(size(obj.amplitude_min));
                    obj.amplitude_max = 1e6 * ones(size(obj.amplitude_max));
                end
            else
                obj.logObj.obj.logObj.error('bossdevice is not ready. Initialize your bossdevice object before further processing. For example, if you are using "bd = bossdevice", run "bd.initialize".');
            end
        end

    end
end
