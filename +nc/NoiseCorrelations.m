%{
nc.NoiseCorrelations (computed) # Noise correlations

-> nc.NoiseCorrelationSet
-> nc.UnitPairs
---
r_noise_avg         : double     # average noise correlation
r_noise_filt        : double     # r_noise after highpass filtering z-scores
r_signal            : double     # signal correlations
r_lt                : double     # long-term component of r_noise
r_st                : double     # short-term component of r_noise
tcc                 : mediumblob # trial cross-correlogram
geom_mean_rate      : double     # average geometric mean firing rate
min_rate            : double     # average minimum firing rate
diff_pref_ori       : double     # difference in preferred orientation
distance            : double     # distance between cells (tetrodes)
max_instab          : double     # max instability for pair
max_contam          : double     # max contamination for pair
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
