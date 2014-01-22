%{
sort.Methods (lookup) # Algorithms used for clustering

sort_method_num     : tinyint unsigned     # clustering method index
---
sort_method_name    : varchar(63) # text description of clustering method
%}

classdef Methods < dj.Relvar
    properties(Constant)
        table = dj.Table('sort.Methods');
    end
    
    methods 
        function self = Methods(varargin)
            self.restrict(varargin{:})
        end
    end
end
