%{
nc.LfpPowerRatioCorrPairs (computed) # LFP power ratio during stimulus presentation

-> nc.LfpPowerRatioCorr
-> nc.UnitPairs
---
r_noise             : double            # noise correlation
delta_r_noise       : double            # noise correlation relative to avg
%}

classdef LfpPowerRatioCorrPairs < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.LfpPowerRatioCorrPairs');
    end
    
    methods 
        function self = LfpPowerRatioCorrPairs(varargin)
            self.restrict(varargin{:})
        end
    end
end
