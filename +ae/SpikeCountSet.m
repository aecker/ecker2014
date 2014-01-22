%{
ae.SpikeCountSet (computed) # Spike counts

-> acq.StimulationSyncDiode
-> ephys.SpikeSet
-> stimulation.StimTrialGroup
-> ae.SpikeCountParams
---
%}

classdef SpikeCountSet < dj.Relvar & dj.AutoPopulate
    properties (Constant)
        table = dj.Table('ae.SpikeCountSet');
        popRel = acq.StimulationSyncDiode * ephys.SpikeSet * stimulation.StimTrialGroup * ae.SpikeCountParams;
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            insert(self, key);
            makeTuples(ae.SpikeCounts, key);
        end
    end
end
