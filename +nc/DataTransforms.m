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
end
