%{
nc.CleanPairSet (computed) # Set of all pairs of units for one recording

-> nc.UnitPairSet
-> nc.CleanPairParams
-> ephys.SpikeSet
-> nc.UnitStatsSet
---
%}

classdef CleanPairSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.CleanPairSet');
        popRel = nc.UnitPairSet * nc.CleanPairParams * nc.UnitStatsSet;
    end
    
    methods 
        function self = CleanPairSet(varargin)
            self.restrict(varargin{:})
        end
    end

    methods (Access = protected)
        function makeTuples(this, key)
            insert(this, key);
            excludePairs = nc.UnitPairMembership & key & ( ...
                (ephys.SingleUnit & key & sprintf('fp + fn > %f', key.max_contam)) + ...
                (nc.UnitStats & key & sprintf('stability > %f', key.min_stability)));
            tuples = fetch((nc.CleanPairSet * nc.UnitPairs - excludePairs) & key);
            insert(nc.CleanPairs, tuples);
        end
    end
end
