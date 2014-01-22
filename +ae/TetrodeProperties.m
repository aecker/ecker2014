%{
ae.TetrodeProperties (manual) # Tetrode properties

-> ae.TetrodeImplants
electrode_num   : tinyint unsigned   # electrode number
---
material        : ENUM("NiCh", "PtIr")  # tetrode material
loc_x           : float     # x coordinate
loc_y           : float     # y coordinate
depth_to_brain = NULL : float     # adjustments until in brain (mu)
depth_to_wm = NULL    : float     # adjustments until in white matter (mu)
%}

classdef TetrodeProperties < dj.Relvar
    properties (Constant)
        table = dj.Table('ae.TetrodeProperties');
    end
end
