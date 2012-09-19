%{
nc.NoiseCorrelationConditions (computed) # Noise correlations

-> nc.NoiseCorrelations
-> nc.GratingConditions
---
r_noise_cond = NULL : double    # noise correlation by condition
geom_mean_rate_cond : double    # average geometric mean firing rate
min_rate_cond       : double    # average minimum firing rate
%}

classdef NoiseCorrelationConditions < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.NoiseCorrelationConditions');
    end
    
    methods 
        function self = NoiseCorrelationConditions(varargin)
            self.restrict(varargin{:})
        end
    end
end
