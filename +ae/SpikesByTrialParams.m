%{
ae.SpikesByTrialParams (manual) # Parameters for spikes arranged by trial

pre_stim_time   : int unsigned          # Time before stimulus onset
post_stim_time  : int unsigned          # Time after stimulus offset
---
%}

classdef SpikesByTrialParams < dj.Relvar
    properties(Constant)
        table = dj.Table('ae.SpikesByTrialParams');
    end
    
    methods 
        function self = SpikesByTrialParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
