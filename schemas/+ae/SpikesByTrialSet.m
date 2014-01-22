%{
ae.SpikesByTrialSet (computed) # Spike times organized by trials

-> stimulation.StimTrialGroup
-> ephys.SpikeSet
---
pre_stim_time                         : float         # start of window (ms before stim onset)
spikesbytrialset_ts=CURRENT_TIMESTAMP : timestamp     # automatic timestamp. Do not edit
%}

% Note: since the times between stimuli are allocated differently to either
% the next or the previous trial between experiments, we here define the
% start of the trial via the showStimulus event and include pre_stim_time
% ms before it. We explicitly don't use the startTrial event for this
% reason.

classdef SpikesByTrialSet < dj.Relvar & dj.AutoPopulate
    properties (Constant)
        table = dj.Table('ae.SpikesByTrialSet');
        popRel = acq.StimulationSyncDiode * ephys.SpikeSet * stimulation.StimTrialGroup;
    end
    
    methods (Access = protected)
        function makeTuples(this, key)
            tuple = key;
            tuple.pre_stim_time = 1000;
            insert(this, tuple);
            for unitKey = fetch(ephys.Spikes & key)'
                fprintf('Unit %d\n', unitKey.unit_id)
                spikes = fetch1(ephys.Spikes & unitKey, 'spike_times');
                k = 0;
                trials = fetch(ephys.Spikes & unitKey ...
                    * (stimulation.StimTrials & key & stimulation.StimTrialEvents('event_type = "showStimulus"')));
                for trial = trials'
                    k = makeTuples(ae.SpikesByTrial, trial, spikes, k);
                end
            end
        end
    end
end
