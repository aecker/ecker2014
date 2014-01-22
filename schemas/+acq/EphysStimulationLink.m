%{
acq.EphysStimulationLink (computed)   # stimulation sessions that were recorded

->acq.Ephys
->acq.Stimulation
->acq.SessionsCleanup
---
%}

classdef EphysStimulationLink < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('acq.EphysStimulationLink');
        popRel = acq.Ephys * (acq.Stimulation - acq.StimulationIgnore) ...
            & acq.SessionsCleanup ...
            & 'ephys_start_time <= (stim_start_time + 10000) AND ephys_stop_time >= (stim_stop_time - 10000)';
    end
    
    methods
        function self = EphysStimulationLink(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access=protected)        
        function makeTuples(self, key)
            insert(self, key);
        end
    end
end
