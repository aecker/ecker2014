%{
nc.LfpGlmParams (manual) # GLM with LFP as input

bin_size        : int unsigned      # bin size (ms)
kfold_cv        : tinyint unsigned  # k-fold cross-validation
---
%}

classdef LfpGlmParams < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.LfpGlmParams');
    end
end
