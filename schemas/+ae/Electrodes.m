%{
ae.Electrodes (manual) # List of electrodes

electrode_num   : tinyint unsigned  # electrode number
---
%}

classdef Electrodes < dj.Relvar
    properties (Constant)
        table = dj.Table('ae.Electrodes');
    end
end
