%{
nc.NoiseCorrelations (computed) # Noise correlations

-> nc.NoiseCorrelationSet
-> nc.UnitPairs
---
r_noise_avg = NULL : double # average noise correlation
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
