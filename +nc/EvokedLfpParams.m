%{
nc.EvokedLfpParams (computed) # stimulus-evoked LFP parameters

min_freq    : double    # highpass cutoff
max_freq    : double    # lowpass cutoff
---
%}

classdef EvokedLfpParams < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.EvokedLfpParams');
    end
    
    methods 
        function self = EvokedLfpParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
