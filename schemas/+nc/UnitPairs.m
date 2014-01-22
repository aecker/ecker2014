%{
nc.UnitPairs (computed) # Pairs of units

-> nc.UnitPairSet
pair_num : smallint unsigned # pair number
---
%}

classdef UnitPairs < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.UnitPairs');
    end
    
    methods 
        function self = UnitPairs(varargin)
            self.restrict(varargin{:})
        end
    end
end
