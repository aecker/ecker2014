%{
detect.Methods (lookup) # Algorithms used for spike detection

detect_method_num  : tinyint unsigned # detection method index
---
detect_method_name : varchar(45)      # text description of detection method
%}

classdef Methods < dj.Relvar
    properties(Constant)
        table = dj.Table('detect.Methods');
    end
    
    methods 
        function self = Methods(varargin)
            self.restrict(varargin{:})
        end
    end
end
