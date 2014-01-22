%{
nc.GpfaResidCorr (computed) # Covariance explained by GPFA model

-> nc.GpfaResidCorrSet
-> nc.GpfaPairs
latent_dim           : tinyint unsigned  # number of latent dimensions
int_bins             : tinyint unsigned  # number of bins to integrate
---
resid_corr_train     : double            # residual correlation on train set
resid_corr_test      : double            # residual correlation on test set
%}

classdef GpfaResidCorr < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.GpfaResidCorr');
    end
end
