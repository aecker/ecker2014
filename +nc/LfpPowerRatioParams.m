%{
nc.LfpPowerRatioParams (manual) # LFP power ratio parameters

low_min     : double    # low frequency min
low_max     : double    # low frequency max
high_min    : double    # high frequency min
high_max    : double    # high frequency max
---
%}

classdef LfpPowerRatioParams < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.LfpPowerRatioParams');
    end
    
    methods
        function self = LfpPowerRatioParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
