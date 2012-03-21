%{
ae.LfpByTrial (computed) # Spike times organized by trials

-> ae.LfpByTrialSet
-> stimulation.StimTrials
electrode_num           : tinyint unsigned  # electrode number
---
lfp_by_trial = NULL     : blob              # LFP for one trial
lfp_by_trial_t0         : double            # timestamp of first LFP sample
%}

classdef LfpByTrial < dj.Relvar
    properties(Constant)
        table = dj.Table('ae.LfpByTrial');
    end
    
    methods 
        function self = LfpByTrial(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key, reader)
            showStimEvent = stimulation.StimTrialEvents(key) & 'event_type = "showStimulus"';
            showStimTime = fetch1(showStimEvent, 'event_time');
            endStimEvent = stimulation.StimTrialEvents(key) & 'event_type = "endStimulus"';
            if ~count(endStimEvent)
                endStimEvent = stimulation.StimTrialEvents(key) & 'event_type LIKE "%Abort"';
            end
            endStimTime = fetch1(endStimEvent, 'event_time');
            first = getSampleIndex(reader, showStimTime - key.pre_stim_time);
            last = getSampleIndex(reader, endStimTime + key.post_stim_time);
            tuple = key;
            tuple.lfp_by_trial = reader(first:last, 1);
            tuple.lfp_by_trial_t0 = reader(first, 't');
            insert(self, tuple);
        end
    end
end
