%{
nc.GpfaSpontResidCorr (computed) # Covariance explained by GPFA model

-> nc.GpfaSpontResidCorrSet
-> nc.GpfaSpontPairs
latent_dim           : tinyint unsigned  # number of latent dimensions
int_bins             : tinyint unsigned  # number of bins to integrate
---
resid_corr_train     : double            # residual correlation on train set
resid_corr_test      : double            # residual correlation on test set
%}

classdef GpfaSpontResidCorr < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.GpfaSpontResidCorr');
    end
end
