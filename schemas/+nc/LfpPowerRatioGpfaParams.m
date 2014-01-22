%{
nc.LfpPowerRatioGpfaParams (lookup) # LFP power ratio parameters

ratio_param_num : tinyint unsigned  # parameter set number
---
low_min         : double            # low frequency min
low_max         : double            # low frequency max
high_min        : double            # high frequency min
high_max        : double            # high frequency max
num_blocks      : tinyint unsigned  # number of blocks
%}

classdef LfpPowerRatioGpfaParams < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.LfpPowerRatioGpfaParams');
    end
    
    methods
        function self = LfpPowerRatioGpfaParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
