%{
sort.SetsCompleted (imported) # Completed clustering sets
->sort.Sets
---
%}

classdef SetsCompleted < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('sort.SetsCompleted');
        popRel = sort.Sets ...
            - (sort.Electrodes * sort.Methods('sort_method_name = "Utah"') - sort.VariationalClusteringFinalize) ...
            - (sort.Electrodes * sort.Methods('sort_method_name = "TetrodesMoG"') - sort.TetrodesMoGFinalize) ...
            - (sort.Electrodes * sort.Methods('sort_method_name = "MultiUnit"') - sort.MultiUnit) ...
            - (sort.Electrodes * sort.Methods('sort_method_name = "MoKsm"') - sort.KalmanFinalize);
    end
    
    methods
        function self = SetsCompleted(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access=protected)        
        function makeTuples(self, key)
            self.insert(key);
        end
    end
end
