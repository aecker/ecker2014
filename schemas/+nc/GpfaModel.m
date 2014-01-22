%{
nc.GpfaModel (computed) # Gaussian process factor analysis model

-> nc.GpfaModelSet
latent_dim      : tinyint unsigned  # number of latent dimensions
cv_run          : tinyint unsigned  # cross-validation run number
---
train_set       : mediumblob        # trial indices for training set
test_set        : mediumblob        # trial indices for test set
seed            : bigint            # random number generator seed
model           : longblob          # GPFA model
log_like_train  : double            # training set log likelihood
log_like_test   : double            # test set log likelihood
%}

classdef GpfaModel < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.GpfaModel');
    end
    
    methods 
        function self = GpfaModel(varargin)
            self.restrict(varargin{:})
        end
    end
end
