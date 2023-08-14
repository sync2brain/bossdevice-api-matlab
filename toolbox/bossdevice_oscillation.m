classdef bossdevice_oscillation < bossdevice
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties
        name
    end
    
    properties (Dependent)
        phase_target
        phase_plusminus
        amplitude_min
        amplitude_max
        lpf_fir_coeffs % Nyquist filter before decimating the signal from 5 kHz to the sample rate of the oscillation
        bpf_fir_coeffs % band pass filter coefficients
        offset_samples
    end
   
    methods
        function obj = bossdevice_oscillation(targetName, ipAddress, name)
            %UNTITLED Construct an instance of this class
            arguments
                targetName {mustBeTextScalar} = '';
                ipAddress {mustBeTextScalar} = '';
                name {mustBeMember(name,{'alpha','beta','theta'})} = 'alpha';
            end
            % Call bossdevice constructor
            obj@bossdevice(targetName, ipAddress);

            obj.name = name;

            if obj.targetObject.isConnected && obj.targetObject.isLoaded
                obj.phase_target = getparam(obj.targetObject, ['mainmodel/EVD/' obj.name], 'phase_target');
                obj.phase_plusminus = getparam(obj.targetObject, ['mainmodel/EVD/' obj.name], 'phase_plusminus');
                obj.amplitude_min = getparam(obj.targetObject, ['mainmodel/EVD/' obj.name], 'amplitude_min');
                obj.amplitude_max = getparam(obj.targetObject, ['mainmodel/EVD/' obj.name], 'amplitude_max');
            else
                warning('bossdevice is not connected. Switch the device on and reinitialize this object.');
            end
        end
              
        
        function phase_target = get.phase_target(obj)
            phase_target = getparam(obj.targetObject, ['mainmodel/EVD/' obj.name], 'phase_target');
        end
        
        function set.phase_target(obj, phi)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            previousValue = obj.phase_target;
            if isscalar(phi)
                newValue = previousValue;
                newValue(1) = phi;
            else
                newValue = phi;
                if ~all(size(previousValue) == size(newValue))
                    warning('unable to set phase target, dimension mismatch')
                    return
                end
            end
            setparam(obj.targetObject, ['mainmodel/EVD/' obj.name], 'phase_target', newValue);
        end

        
        function phase_plusminus = get.phase_plusminus(obj)
            phase_plusminus = getparam(obj.targetObject, ['mainmodel/EVD/' obj.name], 'phase_plusminus');
        end
        
        function set.phase_plusminus(obj, phase_plusminus)
            %set.phase_plusminus Set phase tolerance
            %   A tolerance of pi ignores the phase in generation of events
            setparam(obj.targetObject, ['mainmodel/EVD/' obj.name], 'phase_plusminus', phase_plusminus);
        end

        
        function amplitude_min = get.amplitude_min(obj)
            amplitude_min = getparam(obj.targetObject, ['mainmodel/EVD/' obj.name], 'amplitude_min');
        end
        
        function set.amplitude_min(obj, amplitude_min)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            setparam(obj.targetObject, ['mainmodel/EVD/' obj.name], 'amplitude_min', amplitude_min);
        end        


        function amplitude_max = get.amplitude_max(obj)
            amplitude_max = getparam(obj.targetObject, ['mainmodel/EVD/' obj.name], 'amplitude_max');
        end
        
        function set.amplitude_max(obj, amplitude_max)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            setparam(obj.targetObject, ['mainmodel/EVD/' obj.name], 'amplitude_max', amplitude_max);
        end

        
        function lpf_fir_coeffs = get.lpf_fir_coeffs(obj)
            lpf_fir_coeffs = getparam(obj.targetObject, ['mainmodel/OSC/' obj.name], 'lpf_fir_coeffs');
        end
        
        function set.lpf_fir_coeffs(obj, coeffs)
            setparam(obj.targetObject, ['mainmodel/OSC/' obj.name], 'lpf_fir_coeffs', coeffs)
        end
        
        
        function bpf_fir_coeffs = get.bpf_fir_coeffs(obj)
            bpf_fir_coeffs = getparam(obj.targetObject, ['mainmodel/OSC/' obj.name], 'bpf_fir_coeffs');
        end
        
        function set.bpf_fir_coeffs(obj, coeffs)
            assert(numel(coeffs) <= numel(obj.bpf_fir_coeffs), 'number of coefficients exceeds maximum')
            if numel(coeffs) < numel(obj.bpf_fir_coeffs)
                coeffs(numel(obj.bpf_fir_coeffs)) = 0; % fill with zeros
            end
            setparam(obj.targetObject, ['mainmodel/OSC/' obj.name], 'bpf_fir_coeffs', coeffs)
        end        
        
        function offset_samples = get.offset_samples(obj)
            offset_samples = getparam(obj.targetObject, ['mainmodel/OSC/' obj.name], 'ipe_offset_samples');
        end
        
        function set.offset_samples(obj, weights)
            setparam(obj.targetObject, ['mainmodel/OSC/' obj.name], 'ipe_offset_samples', weights)
        end

        
        function obj = ignore(obj, varargin)
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
        end
        
    end
end