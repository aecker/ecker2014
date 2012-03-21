%{
ae.SpikeCountParams (manual) # Parameters for spike counts

spike_count_start : float # start of counting window (ms, relative to stim onset)
spike_count_end   : float # end of window
---
%}

classdef SpikeCountParams < dj.Relvar
    properties(Constant)
        table = dj.Table('ae.SpikeCountParams');
    end
    
    methods 
        function self = SpikeCountParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
