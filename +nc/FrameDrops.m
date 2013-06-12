%{
nc.FrameDrops (manual)       # dropped frames (happens on acute setup only)

subject_id          : int unsigned      # unique identifier for subject
setup               : tinyint unsigned  # setup number
session_start_time  : bigint            # start session timestamp
stim_start_time     : bigint            # timestamp for stimulation start
ephys_start_time    : bigint            # start session timestamp
frame_drop_time     : double            # timestamp of dropped frame
---
trial_num           : int               # trial number
%}

classdef FrameDrops < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.FrameDrops');
    end
    
    methods 
        function self = FrameDrops(varargin)
            self.restrict(varargin{:})
        end
    end
end
