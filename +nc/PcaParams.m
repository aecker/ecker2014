%{
nc.PcaParams (manual) # PCA parameters

max_instability   : double            # minimum stability criterion
---
%}

classdef PcaParams < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.PcaParams');
    end
    
    methods 
        function self = PcaParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
