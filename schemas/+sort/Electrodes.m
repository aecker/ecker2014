%{
sort.Electrodes (imported) # clustering for one electrode

->sort.Sets
->detect.Electrodes
---
%}

classdef Electrodes < dj.Relvar
    properties(Constant)
        table = dj.Table('sort.Electrodes');
    end
    
    methods 
        function self = Electrodes(varargin)
            self.restrict(varargin{:})
        end
    end
end
