%{
sort.Params (manual) # parameters being used for spike sorting

-> detect.Params
-> sort.Methods
---
%}

classdef Params < dj.Relvar
    properties(Constant)
        table = dj.Table('sort.Params');
    end
    
    methods 
        function self = Params(varargin)
            self.restrict(varargin{:})
        end
    end
end
