%{
nc.CleanPairParams (manual) # Parameters defining a clean pair

max_contam      : double    # maximum contamination
max_instability : double    # minimum stability
---
%}

classdef CleanPairParams < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.CleanPairParams');
    end
    
    methods 
        function self = CleanPairParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
