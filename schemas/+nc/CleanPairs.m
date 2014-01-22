%{
nc.CleanPairs (computed) # Clean pairs of units

-> nc.CleanPairSet
-> nc.UnitPairs
---
%}

classdef CleanPairs < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.CleanPairs');
    end
    
    methods 
        function self = CleanPairs(varargin)
            self.restrict(varargin{:})
        end
    end
end
