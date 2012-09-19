%{
nc.LnpModel2Cond (computed) # Firing rate prediction from LFP (per condition)

-> nc.GratingConditions
-> nc.LnpModel2
---
params          : blob          # all parameters (#conditions x #basisfun + 1)
deviance        : double        # deviance of model fit
stats           : mediumblob    # stats returned by glmfit
lfp_param       : double        # parameter for lfp dependence (scalar)
rate            : double        # firing rate
lfp_data        : longblob      # filtered LFP
spike_data      : longblob      # binned spikes
warning         : boolean       # was a warning issued during fitting?
%}

classdef LnpModel2Cond < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.LnpModel2Cond');
    end
    
    methods 
        function self = LnpModel2Cond(varargin)
            self.restrict(varargin{:})
        end
    end
end
