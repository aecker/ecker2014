%{
sort.Sets (imported) # Set of electrodes to cluster

-> sort.Params
-> detect.Sets
---
sort_set_path : VARCHAR(255) # folder containing spike sorting files
%}

classdef Sets < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('sort.Sets');
        popRel = sort.Params * detect.Sets;
    end
    
    methods
        function self = Sets(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access=protected)        
        function makeTuples(self, key)
            detectPath = fetch1(detect.Sets(key), 'detect_set_path');
            sortMethod = fetch1(sort.Methods(key), 'sort_method_name');
            tuple = key;
            tuple.sort_set_path = [detectPath '/' sortMethod];
            self.insert(tuple);
            
            % insert electrodes
            electrodes =  dj.struct.join(key,fetch(detect.Electrodes(key)));
            insert(sort.Electrodes, electrodes);
        end
    end
end
