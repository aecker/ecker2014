%{
nc.LnpModel3Params (lookup) # Parameters for LNP model

method      : enum("glm", "net")    # regularization method
num_trials  : int                   # number of trials to use (-1 = all)
stim_time   : int                   # stimulus time to use (-1 = all)
---
%}

classdef LnpModel3Params < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.LnpModel3Params');
    end
    
    methods 
        function self = LnpModel3Params(varargin)
            self.restrict(varargin{:})
        end
    end
end
