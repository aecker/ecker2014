%{
ae.SpikeCounts (computed) # Spike counts

-> ae.SpikeCountSet
-> ephys.Spikes
-> stimulation.StimTrials
---
spike_count : int # number of spikes in counting window
%}

classdef SpikeCounts < dj.Relvar
    properties (Constant)
        table = dj.Table('ae.SpikeCounts');
    end
    
    methods
        function makeTuples(self, key)
            b = key.spike_count_start;
            e = key.spike_count_end;
            for unitKey = fetch(ephys.Spikes & key)'
                fprintf('Unit %d\n', unitKey.unit_id)
                t = fetch1(ephys.Spikes & unitKey, 'spike_times');
                nSpikes = numel(t);
                k = 0;
                trials = fetch((ephys.Spikes & unitKey) ...
                    * ((stimulation.StimTrials * stimulation.StimTrialEvents & key) ...
                        & 'valid_trial = true AND event_type = "showStimulus"') ...
                    * (ae.SpikeCountParams & key), 'event_time -> show_stim_time');
                spikeCount = cell(numel(trials), 1);
                trialNum = 1;
                for trial = trials'
                    while k > 0 && t(k) > trial.show_stim_time + b
                        k = k - 1;
                    end
                    while k < nSpikes && t(k + 1) < trial.show_stim_time + b
                        k = k + 1;
                    end
                    k0 = k;
                    while k < nSpikes && t(k + 1) < trial.show_stim_time + e
                        k = k + 1;
                    end
                    spikeCount{trialNum} = k - k0;
                    trialNum = trialNum + 1;
                end
                trials = rmfield(trials, 'show_stim_time');
                trials = rmfield(trials, 'event_type');
                [trials.spike_count] = deal(spikeCount{:});
                insert(self, trials);
            end
        end
    end
end
