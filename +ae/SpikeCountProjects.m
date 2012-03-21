%{
ae.SpikeCountProjects (manual) # Mapping from parameters to projects

-> ae.SpikeCountParams
-> ae.Projects
---
%}

classdef SpikeCountProjects < dj.Relvar
    properties(Constant)
        table = dj.Table('ae.SpikeCountProjects');
    end
    
    methods 
        function self = SpikeCountProjects(varargin)
            self.restrict(varargin{:})
        end
    end
end
