%{
nc.LfpPowerRatioParams (manual) # LFP power ratio parameters

split_freq  : double    # frequency at which to split power spectrum
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
