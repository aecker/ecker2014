%{
nc.UnitPairMembership (computed) # Pairs of units

-> nc.UnitPairs
-> ephys.Spikes
---
%}

classdef UnitPairMembership < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.UnitPairMembership');
    end
    
    methods 
        function self = UnitPairMembership(varargin)
            self.restrict(varargin{:})
        end
    end
end
