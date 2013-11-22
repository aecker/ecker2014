%{
nc.LfpPowerRatioGpfa (computed) # LFP power ratio and GPFA

-> nc.LfpPowerRatioGpfaSet
block_num           : tinyint unsigned  # block number
---
power_ratio         : double            # LFP power ratio
power_low           : double            # LFP low-frequency power
power_high          : double            # LFP high-frequency power
delta_power_ratio   : double            # relative LFP power ratio
delta_power_low     : double            # relative LFP low-frequency power
delta_power_high    : double            # relative LFP high-frequency power
var_x               : double            # variance of latent factor
delta_var_x         : double            # relative variance of latent factor
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
