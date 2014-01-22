%{
nc.AnalysisParams (manual) # Some basic analysis parameters

max_instability     : double    # maximum instability score
min_cells           : int       # minumum number of cells
min_trials          : int       # minimum number of trials
---
%}

classdef AnalysisParams < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.AnalysisParams');
    end
    
    methods 
        function self = AnalysisParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
