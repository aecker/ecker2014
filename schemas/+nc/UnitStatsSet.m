%{
nc.UnitStatsSet (computed) # Several summary stats for units

-> ae.SpikeCountSet
-> ae.SpikesByTrialSet
-> nc.Gratings
---
%}

classdef UnitStatsSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.UnitStatsSet');
        popRel = ae.SpikeCountSet * ae.SpikesByTrialSet * nc.Gratings;
    end
    
    methods 
        function self = UnitStatsSet(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            self.insert(key);
            for unitKey = fetch(ephys.Spikes(key) * (self.popRel & key))'
                makeTuples(nc.UnitStats, unitKey)
            end
        end
    end
end
