%{
ae.SpikesByTrialSet (computed) # Spike times organized by trials

-> stimulation.StimTrialGroup
-> ephys.SpikeSet
---
spikesbytrialset_ts=CURRENT_TIMESTAMP: timestamp             # automatic timestamp. Do not edit
%}

classdef SpikesByTrialSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ae.SpikesByTrialSet');
        popRel = (acq.StimulationSyncDiode & (ae.ProjectsStimulation * ae.SpikesByTrialProjects)) ...
            * ephys.SpikeSet * stimulation.StimTrialGroup;
    end
    
    methods 
        function self = SpikesByTrialSet(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(this, key)
            insert(this, key);
            for unitKey = fetch(ephys.Spikes(key))'
                fprintf('Unit %d\n', unitKey.unit_id)
                spikes = fetch1(ephys.Spikes(unitKey), 'spike_times');
                k = 0;
                trials = fetch(ephys.Spikes(unitKey) ...
                    * (stimulation.StimTrials(key) & stimulation.StimTrialEvents('event_type = "showStimulus"')));
                for trial = trials'
                    k = makeTuples(ae.SpikesByTrial, trial, spikes, k);
                end
            end
        end
    end
end
