%{
nc.GpfaDataTransforms (lookup) # GPFA data transformations

transform_num           : tinyint unsigned  # transformation number
---
transform_name = ""     : varchar(255)      # name of the transformation
transform_formula = ""  : varchar(255)      # formula
%}

classdef GpfaDataTransforms < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.GpfaDataTransforms');
    end
end
