%{
acq.TimestampSources (lookup)       # events recorded by the timestamper

channel : tinyint unsigned # channel that received a message
setup   : tinyint unsigned # setup number
---
source  : enum('Ephys','Stimulation','Behavior','AOD') # source that triggered the timestamp
%}

classdef TimestampSources < dj.Relvar
    properties(Constant)
        table = dj.Table('acq.TimestampSources');
    end
    
    methods 
        function self = TimestampSources(varargin)
            self.restrict(varargin{:})
        end
    end
end
