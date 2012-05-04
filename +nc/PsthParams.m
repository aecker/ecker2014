% PSTH parameters.
%   See nc.Psth

%{
nc.PsthParams (manual) # PSTH parameters

bin_size                : int unsigned  # bin size for PSTH (ms)
---
%}

classdef PsthParams < dj.Relvar
    properties (Constant)
        table = dj.Table('nc.PsthParams');
    end
    
    methods 
        function self = PsthParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
