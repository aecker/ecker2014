%{
nc.EvokedLfpStims (computed) # stims used for eevoked LFP profile

-> nc.EvokedLfpProfile
-> acq.EphysStimulationLink
---
%}

classdef EvokedLfpStims < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.EvokedLfpStims');
    end
    
    methods 
        function self = EvokedLfpStims(varargin)
            self.restrict(varargin{:})
        end
    end
end
