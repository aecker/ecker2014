%{
nc.LfpPowerRatioGpfa (computed) # LFP power ratio and GPFA

-> nc.LfpPowerRatioGpfaSet
block_num           : tinyint unsigned  # block number
---
block_rank          : tinyint unsigned  # block rank according to power ratio
power_ratio         : double            # LFP power ratio
delta_power_ratio   : double            # LFP power ratio
mean_x              : double            # mean of first latent factor
var_x               : double            # variance of first latent factor
%}

classdef LfpPowerRatioGpfa < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.LfpPowerRatioGpfa');
    end
    
    methods 
        function self = LfpPowerRatioGpfa(varargin)
            self.restrict(varargin{:})
        end
    end
end
