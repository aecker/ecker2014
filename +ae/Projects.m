%{
ae.Projects (manual) # Assigns stimulations to projects

project_name : ENUM('NoiseCorrAnesthesia') # Name of the project
---
%}

classdef Projects < dj.Relvar
    properties(Constant)
        table = dj.Table('ae.Projects');
    end
    
    methods 
        function self = Projects(varargin)
            self.restrict(varargin{:})
        end
    end
end
