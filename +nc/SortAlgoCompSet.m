%{
nc.SortAlgoCompSet (computed) # Comparing spike sorting algorithms

-> sort.SetsCompleted
%}


classdef SortAlgoCompSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.SortAlgoCompSet');
        popRel = sort.SetsCompleted('sort_method_num = 5') & ...
            (acq.Ephys & sort.SetsCompleted('sort_method_num = 2'));
    end
    
    methods 
        function self = SortAlgoCompSet(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            self.insert(key);
            for key = fetch(sort.Electrodes(key))'
                makeTuples(nc.SortAlgoComp, key);
            end
        end
    end
end
