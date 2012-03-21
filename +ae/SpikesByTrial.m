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
            showStimEvent = stimulation.StimTrialEvents(key) & 'event_type = "showStimulus"';
            showStimTime = fetch1(showStimEvent, 'event_time');
            endStimEvent = stimulation.StimTrialEvents(key) & 'event_type = "endStimulus"';
            if ~count(endStimEvent)
                endStimEvent = stimulation.StimTrialEvents(key) & 'event_type LIKE "%Abort"';
            end
            endStimTime = fetch1(endStimEvent, 'event_time');
            pre = key.pre_stim_time;
            post = key.post_stim_time;
            while k > 0 && spikes(k) > showStimTime - pre
                k = k - 1;
            end
            nSpikes = numel(spikes);
            while k < nSpikes && spikes(k + 1) < showStimTime - pre
                k = k + 1;
            end
            k0 = k;
            while k < nSpikes && spikes(k + 1) < endStimTime + post
                k = k + 1;
            end
            tuple.spikes_by_trial = spikes(k0 + 1 : k) - showStimTime;
            insert(self, tuple);
        end
    end
end
