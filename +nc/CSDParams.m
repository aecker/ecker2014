%{
nc.CSDParams (manual) # CSD parameters

min_confidence  : double    # minimum confidence required in depth adjustment
---
%}

classdef CSDParams < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.CSDParams');
    end
    
    methods 
        function self = CSDParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
