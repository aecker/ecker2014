%{
nc.GpfaVE (computed) # Variance explained for GPFA model

-> nc.GpfaResidCorrSet
-> nc.GpfaUnits
latent_dim  : tinyint unsigned  # number of latent dimensions
int_bins    : tinyint unsigned  # number of bins to integrate
---
ve_train    : double            # avg var expl on train set model based
ve_test     : double            # avg var expl on test set model based
%}

classdef GpfaVE < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.GpfaVE');
    end
end
