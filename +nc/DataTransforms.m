%{
nc.DataTransforms (lookup) # data transformations

transform_num   : tinyint unsigned  # transformation number
---
name = ""       : varchar(255)      # name of the transformation
formula = ""    : varchar(255)      # formula
inverse = ""    : varchar(255)      # formula for inversion
%}

classdef DataTransforms < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.DataTransforms');
    end
    
    methods
        function y = transform(relvar, x) %#ok
            % Transform data x using transform defined by relvar.
            %   y = transform(relvar, x)
            
            assert(count(relvar) == 1, 'Relvar must be scalar!')
            y = eval(fetch1(relvar, 'formula'));
        end
        
        function y = invert(relvar, x) %#ok
            % Compute inverse of transformation defined by relvar for x.
            
            assert(count(relvar) == 1, 'Relvar must be scalar!')
            y = eval(fetch1(relvar, 'inverse'));
        end
    end 
end
