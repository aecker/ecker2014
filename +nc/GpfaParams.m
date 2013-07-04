%{
nc.GpfaParams (manual) # GPFA model parameters

gpfa_param_num  : tinyint unsigned  # parameter set number
---
bin_size        : int unsigned      # bin size (ms)
max_latent_dim  : tinyint unsigned  # max number of latent dimensions
kfold_cv        : tinyint unsigned  # k-fold cross-validation
zscore          : boolean           # convert to z-scores?
max_instability : double            # minimum stability criterion
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
