%{
ae.LfpByTrialParams (manual) # Parameters for LFP arranged by trial

-> ae.LfpFilter
pre_stim_time   : int unsigned          # Time before stimulus onset
post_stim_time  : int unsigned          # Time after stimulus offset
---
%}

classdef LfpByTrialParams < dj.Relvar
    properties(Constant)
        table = dj.Table('ae.LfpByTrialParams');
    end
    
    methods 
        function self = LfpByTrialParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
