%{
nc.CrossCorr (computed) # Cross-correlogram

-> nc.CrossCorrSet
-> nc.UnitPairs
---
ccg                 : mediumblob    # cross-correlogram
r_ccg               : mediumblob    # r_ccg normalized by variance
r_ccg_bair          : mediumblob    # r_ccg with Bair's method (integrate var)
r_ccg_shift         : mediumblob    # r_ccg using shift predictor
r_ccg_shift_bair    : mediumblob    # r_ccg using shift predictor + Bair
%}

classdef CrossCorr < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.CrossCorr');
    end
end
