%{
ae.SpikesByTrial (computed) # Spike times organized by trials

-> ae.SpikesByTrialSet
-> ephys.Spikes
-> stimulation.StimTrials
---
spikes_by_trial = NULL : blob # Aligned spike times for one trial
%}

classdef SpikesByTrial < dj.Relvar
    properties(Constant)
        table = dj.Table('ae.SpikesByTrial');
    end
    
    methods 
        function self = SpikesByTrial(varargin)
            self.restrict(varargin{:})
        end
        
        function k = makeTuples(self, key, spikes, k)
            tuple = key;
            startTrial = fetch1(stimulation.StimTrialEvents(key) & 'event_type = "showStimulus"', 'event_time');
            totalTrials = count(stimulation.StimTrials(rmfield(key, 'trial_num')));
            if key.trial_num < totalTrials
                endTrial = fetch1(stimulation.StimTrialEvents( ...
                    setfield(key, 'trial_num', key.trial_num + 1)) & 'event_type = "showStimulus"', 'event_time'); %#ok
            else
                endTrial = fetch1(stimulation.StimTrialEvents(key), 'max(event_time) -> t') + 2000;
            end
            showStim = fetch1(stimulation.StimTrialEvents(key) & 'event_type = "showStimulus"', 'event_time');
            while k > 0 && spikes(k) > startTrial
                k = k - 1;
            end
            nSpikes = numel(spikes);
            while k < nSpikes && spikes(k + 1) < startTrial
                k = k + 1;
            end
            k0 = k;
            while k < nSpikes && spikes(k + 1) < endTrial
                k = k + 1;
            end
            tuple.spikes_by_trial = spikes(k0 + 1 : k) - showStim;
            insert(self, tuple);
        end
    end
end
