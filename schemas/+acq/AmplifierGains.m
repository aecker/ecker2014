% Pre-amplifier gains per ephys recording and electrode.
%   For some recording systems (such as Neuralynx and Blackrock) the
%   pre-amplifiers have non-unity gain or the files contain digital numbers
%   in a pre-defined range rather than voltages. To be able to convert
%   those numbers to muV we enter the gains here.

%{
acq.AmplifierGains (manual) # preamplifier gains
      
-> acq.Ephys
electrode_num         : tinyint unsigned # electrode number in array
---
preamp_gain : double     # preamp gain
%}

classdef AmplifierGains < dj.Relvar
    properties(Constant)
        table = dj.Table('acq.AmplifierGains');
    end
    
    methods 
        function self = AmplifierGains(varargin)
            self.restrict(varargin{:})
        end
    end
end
