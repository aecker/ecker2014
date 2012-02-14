%{
ae.ProjectsStimulation (manual) # Assigns stimulations to projects

-> acq.Stimulation
-> ae.Projects
---
%}

classdef ProjectsStimulation < dj.Relvar
    properties(Constant)
        table = dj.Table('ae.ProjectsStimulation');
    end
    
    methods 
        function self = ProjectsStimulation(varargin)
            self.restrict(varargin{:})
        end
    end
end
