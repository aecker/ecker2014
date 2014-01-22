%{
acq.StimulationSyncDiode (computed)   # synchronization to photodiode

->acq.StimulationSync
->acq.EphysStimulationLink
---
%}

classdef StimulationSyncDiode < dj.Relvar
    properties(Constant)
        table = dj.Table('acq.StimulationSyncDiode');
    end
    
    methods
        function self = StimulationSyncDiode(varargin)
            self.restrict(varargin{:})
        end
    end
end
