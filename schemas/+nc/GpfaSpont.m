%{
nc.GpfaSpont (computed) # GPFA model on spontaneous acitvity (intertrial)

-> nc.GpfaSpontSet
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

classdef GpfaSpont < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.GpfaSpont');
    end
end
