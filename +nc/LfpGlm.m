%{
nc.LfpGlm (computed) # GLM with LFP as input

-> nc.LfpGlmSet
-> nc.UnitStatsConditions
cv_run          : tinyint unsigned  # CV run
---
lfp_weight      : double            # LFP weight
psth_weights    : mediumblob        # PSTH weights
all_weights     : mediumblob        # all weights (LFP first)
ve_train        : double            # variance explained on train set
ve_test         : double            # variance explained on test set
ve_train_log    : double            # VE log-transformed on train set
ve_test_log     : double            # VE log-transformed on test set
%}

classdef LfpGlm < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.LfpGlm');
    end
end
