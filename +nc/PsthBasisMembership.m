% PSTHs included in basis set
%   See nc.PsthBasis

%{
nc.PsthBasisMembership (computed) # Membership in basis set

-> nc.PsthSet
-> nc.PsthBasis
---
%}

classdef PsthBasisMembership < dj.Relvar
    properties (Constant)
        table = dj.Table('nc.PsthBasisMembership');
    end
    
    methods 
        function self = PsthBasisMembership(varargin)
            self.restrict(varargin{:})
        end
    end
end
