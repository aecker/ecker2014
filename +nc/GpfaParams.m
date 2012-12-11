%{
nc.GpfaParams (manual) # GPFA model parameters

bin_size    : int unsigned      # bin size (ms)
kfold_cv    : tinyint unsigned  # k-fold cross-validation
---
%}

classdef GpfaParams < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.GpfaParams');
    end
end
