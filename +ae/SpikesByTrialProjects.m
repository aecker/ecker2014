%{
ae.SpikesByTrialProjects (manual) # Projects for which it should be imported

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
