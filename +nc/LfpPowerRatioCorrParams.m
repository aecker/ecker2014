%{
nc.LfpPowerRatioCorrParams (manual) # LFP power ratio parameters

low_min     : double            # low frequency min
low_max     : double            # low frequency max
high_min    : double            # high frequency min
high_max    : double            # high frequency max
num_blocks  : tinyint unsigned  # number of blocks
---
%}

classdef LfpPowerRatioCorrParams < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.LfpPowerRatioCorrParams');
    end
    
    methods
        function self = LfpPowerRatioCorrParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
