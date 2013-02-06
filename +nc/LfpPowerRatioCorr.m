%{
nc.LfpPowerRatioCorr (computed) # LFP power ratio during stimulus presentation

-> nc.LfpPowerRatioCorrSet
block_num           : tinyint unsigned  # block number
---
power_ratio         : double            # LFP power ratio
delta_power_ratio   : double            # power ratio relative to average of session
block_rank          : tinyint unsigned  # block rank according to power ratio
%}

classdef LfpPowerRatioCorr < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.LfpPowerRatioCorr');
    end
    
    methods 
        function self = LfpPowerRatioCorr(varargin)
            self.restrict(varargin{:})
        end
    end
end
