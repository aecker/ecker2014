%{
nc.SpikeCountSet (computed) # Spike counts

-> acq.StimulationSyncDiode
-> ephys.SpikeSet
-> stimulation.StimTrialGroup
-> nc.SpikeCountParams
---
%}

classdef SpikeCountSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.SpikeCountSet');
        popRel = (acq.StimulationSyncDiode & (ae.ProjectsStimulation * nc.SpikeCountProjects)) ...
            * ephys.SpikeSet * stimulation.StimTrialGroup * nc.SpikeCountParams;
    end
    
    methods 
        function self = SpikeCountSet(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            insert(self, key);
            makeTuples(nc.SpikeCounts, key);
        end
    end
end
