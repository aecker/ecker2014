%{
ae.LfpByTrialProjects (manual) # Mapping from parameters to projects

-> ae.LfpByTrialParams
-> ae.Projects
---
%}

classdef LfpByTrialProjects < dj.Relvar
    properties(Constant)
        table = dj.Table('ae.LfpByTrialProjects');
    end
    
    methods 
        function self = LfpByTrialProjects(varargin)
            self.restrict(varargin{:})
        end
    end
end
