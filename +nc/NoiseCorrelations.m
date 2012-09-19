%{
nc.NoiseCorrelations (computed) # Noise correlations

-> nc.NoiseCorrelationSet
-> nc.UnitPairs
---
r_noise_avg = NULL : double    # average noise correlation
r_signal           : double    # signal correlations
geom_mean_rate     : double    # average geometric mean firing rate
min_rate           : double    # average minimum firing rate
diff_pref_ori      : double    # difference in preferred orientation
distance           : double    # distance between cells (tetrodes)
%}

classdef NoiseCorrelations < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.NoiseCorrelations');
    end
    
    methods 
        function self = NoiseCorrelations(varargin)
            self.restrict(varargin{:})
        end
    end
end
