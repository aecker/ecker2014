%{
nc.PairStats (computed) # Several summary stats for unit pairs

-> nc.PairStatsSet
-> nc.UnitPairs
---
geom_mean_rate  : double    # average geometric mean firing rate
min_rate        : double    # average minimum firing rate
diff_pref_ori   : double    # difference in preferred orientation
r_signal        : double    # signal correlations
%}

classdef PairStats < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.PairStats');
    end
    
    methods 
        function self = PairStats(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            [rates, pref] = fetchn(nc.OriTuning * nc.UnitPairMembership(key), 'dir_mean_rate', 'pref_ori');
            rates = cat(1, rates{:});
            tuple = key;
            tuple.geom_mean_rate = mean(sqrt(prod(rates, 1)));
            tuple.min_rate = mean(min(rates, [], 1));
            tuple.diff_pref_ori = abs(angle(exp(2i * (pref(1) - pref(2))))) / 2;
            tuple.r_signal = corr(rates(1, :)', rates(2, :)');
            self.insert(tuple);
        end
    end
end
