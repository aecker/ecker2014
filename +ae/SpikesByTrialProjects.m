%{
ae.SpikesByTrialProjects (manual) # Mapping from parameters to projects

-> ae.SpikesByTrialParams
-> ae.Projects
---
%}

classdef SpikesByTrialProjects < dj.Relvar
    properties(Constant)
        table = dj.Table('ae.SpikesByTrialProjects');
    end
    
    methods 
        function self = SpikesByTrialProjects(varargin)
            self.restrict(varargin{:})
        end
    end
end
