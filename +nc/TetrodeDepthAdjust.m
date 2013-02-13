%{
nc.TetrodeDepthAdjust (computed) # fine adjustment of relative depths

-> nc.TetrodeDepthAdjustSet
electrode_num   : tinyint unsigned  # electode number
---
depth_adjust    : double            # depth adjustment
confidence      : double            # confidence for adjustment value
%}

classdef TetrodeDepthAdjust < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.TetrodeDepthAdjust');
    end

    methods
        function self = TetrodeDepthAdjust(varargin)
            self.restrict(varargin{:})
        end
    end
end
