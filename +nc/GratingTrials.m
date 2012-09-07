%{
nc.GratingTrials (computed) # single trial in grating experiment

-> nc.Gratings
-> stimulation.StimTrials
---
-> nc.GratingConditions
%}

classdef GratingTrials < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.GratingTrials');
    end
    
    methods 
        function self = GratingTrials(varargin)
            self.restrict(varargin{:})
        end
    end
end
