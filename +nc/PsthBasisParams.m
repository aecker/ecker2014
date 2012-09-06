% PSTH basis parameters.
%   See nc.PsthBasis

%{
nc.PsthBasisParams (manual) # PSTH basis parameters

stimulus_time       : int unsigned  # stimulus time
---
%}

classdef PsthBasisParams < dj.Relvar
    properties (Constant)
        table = dj.Table('nc.PsthBasisParams');
    end
    
    methods 
        function self = PsthBasisParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
