%{
nc.SpikeCountProjects (manual) # Mapping from parameters to projects

-> nc.SpikeCountParams
-> ae.Projects
---
%}

classdef SpikeCountProjects < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.SpikeCountProjects');
    end
    
    methods 
        function self = SpikeCountProjects(varargin)
            self.restrict(varargin{:})
        end
    end
end
