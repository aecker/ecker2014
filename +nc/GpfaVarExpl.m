%{
nc.GpfaVarExpl (computed) # Variance explained for GPFA model

-> nc.GpfaUnits
-> nc.GpfaCovExpl
---
var_expl_train  : double    # percent variance explained on train set
var_expl_test   : double    # percent variance explained on test set
%}

classdef GpfaVarExpl < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.GpfaVarExpl');
    end

    methods
        function self = GpfaVarExpl(varargin)
            self.restrict(varargin{:})
        end
    end
end
