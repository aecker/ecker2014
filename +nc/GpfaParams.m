%{
nc.GpfaParams (manual) # GPFA model parameters

bin_size    : int unsigned      # bin size (ms)
kfold_cv    : tinyint unsigned  # k-fold cross-validation
zscore      : boolean           # convert to z-scores?
---
%}

classdef GpfaParams < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.GpfaParams');
    end
    
    methods 
        function self = GpfaParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
