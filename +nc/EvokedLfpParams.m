%{
nc.EvokedLfpParams (manual) # stimulus-evoked LFP parameters

min_freq    : double    # highpass cutoff
max_freq    : double    # lowpass cutoff
exp_type    : ENUM("AcuteGratingExperiment", "FlashingBar")   # type of experiment
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
