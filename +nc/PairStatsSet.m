%{
nc.PairStatsSet (computed) # Several summary stats for unit pairs

-> nc.UnitPairSet
-> ae.SpikeCountSet
-> nc.OriTuningSet
---
-> ae.TetrodeImplants
%}

classdef PairStatsSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.PairStatsSet');
        popRel = (nc.UnitPairSet * ae.SpikeCountSet * nc.OriTuningSet) & ae.TetrodeImplantsEphysLink;
    end
    
    methods 
        function self = PairStatsSet(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            tuple = key;
            tuple.implant_num = fetch1(ae.TetrodeImplantsEphysLink(key), 'implant_num');
            self.insert(tuple);
            for pairKey = fetch(nc.UnitPairs(key) * (self.popRel & key))'
                makeTuples(nc.PairStats, pairKey)
            end
        end
    end
end
