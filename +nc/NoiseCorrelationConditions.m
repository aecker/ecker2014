%{
nc.NoiseCorrelationConditions (computed) # Noise correlations

-> nc.NoiseCorrelations
-> nc.GratingConditions
---
r_noise_cond = NULL : double # noise correlation by condition
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
