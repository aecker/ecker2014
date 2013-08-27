%{
nc.AnalysisUnits (computed) # Units to use for analysis

-> nc.AnalysisStims
-> nc.UnitStats
---
%}

classdef AnalysisUnits < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.AnalysisUnits');
        popRel = nc.AnalysisStims * nc.UnitStats & 'tac_instability < max_instability';
    end
    
    methods 
        function self = AnalysisUnits(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            self.insert(key);
        end
    end
end
