%{
nc.PairStats (computed) # Several summary stats for unit pairs

-> nc.PairStatsSet
-> nc.UnitPairs
---
geom_mean_rate  : double    # average geometric mean firing rate
min_rate        : double    # average minimum firing rate
diff_pref_ori   : double    # difference in preferred orientation
r_signal        : double    # signal correlations
distance        : double    # distance between cells (tetrodes)
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
            [x, y] = fetchn(nc.UnitPairMembership(key) * ephys.Spikes * ae.TetrodeProperties, 'loc_x', 'loc_y');
            rates = cat(1, rates{:});
            tuple = key;
            tuple.geom_mean_rate = mean(sqrt(prod(rates, 1)));
            tuple.min_rate = mean(min(rates, [], 1));
            tuple.diff_pref_ori = abs(angle(exp(2i * (pref(1) - pref(2))))) / 2;
            tuple.r_signal = corr(rates(1, :)', rates(2, :)');
            if isnan(tuple.r_signal) % i.e. at least one cell no spikes 
                tuple.r_signal = 0;
            end
            tuple.distance = sqrt(diff(x).^2 + diff(y).^2);
            self.insert(tuple);
        end
    end
end
