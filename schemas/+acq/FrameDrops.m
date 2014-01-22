%{
acq.FrameDrops (manual)     # dropped frames (happens on acute setup only)

-> acq.Stimulation
-> acq.Ephys
trial_num           : int unsigned  # trial number
frame_num           : int unsigned  # frame number
---
shift               : tinyint       # number of frames shifted
%}

classdef FrameDrops < dj.Relvar
    properties(Constant)
        table = dj.Table('acq.FrameDrops');
    end
    
    methods 
        function self = FrameDrops(varargin)
            self.restrict(varargin{:})
        end
    end
end
