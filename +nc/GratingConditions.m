%{
nc.GratingConditions (computed) # single trial in grating experiment

-> nc.Gratings
-> stimulation.StimConditions
---
orientation   : float   # grating orientation
direction     : float   # direction of motion of grating
contrast      : float   # grating contrast
disk_size     : float   # stimulus size in px
initial_phase : float   # phase of grating at start [0 ... 2pi]
%}

classdef GratingConditions < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.GratingConditions');
    end
    
    methods 
        function self = GratingConditions(varargin)
            self.restrict(varargin{:})
        end
    end
end
