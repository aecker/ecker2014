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
            totalTrials = count(stimulation.StimTrials(rmfield(key, 'trial_num')));
            if key.trial_num < totalTrials
                endTrial = fetch1(stimulation.StimTrialEvents( ...
                    setfield(key, 'trial_num', key.trial_num + 1)) & 'event_type = "showStimulus"', 'event_time'); %#ok
            else
                endTrial = fetch1(stimulation.StimTrialEvents(key), 'max(event_time) -> t') + 2000;
            end
            showStim = fetch1(stimulation.StimTrialEvents(key) & 'event_type = "showStimulus"', 'event_time');
            startTrial = showStim - fetch1(ae.SpikesByTrialSet(key), 'pre_stim_time');
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
    
    methods(Static)
        function counts = spikeCount(relvar, win)
            % Get spike counts.
            %   counts = ae.SpikesByTrial.spikeCount(relvar, win) returns
            %   the spike counts for each tuple in relvar. The counting
            %   window is specified by the two-element vector win (times
            %   relative to stimulus onset).
            %
            % Note that you can't rely on any particular order when using
            % this function. Use spikeCountStruct if the order of the data
            % is important.
            spikes = fetchn(relvar, 'spikes_by_trial');
            counts = cellfun(@(x) sum(x > win(1) & x < win(2)), spikes);
        end
        
        function result = spikeCountStruct(relvar, win, varargin)
            % Get spike counts including primary keys.
            %   result = ae.SpikesByTrial.spikeCountStruct(relvar, win)
            %   returns a structure containing spike counts and primary
            %   keys for each tuple in relvar. The counting window is
            %   specified by the two-element vector win (times relative to
            %   stimulus onset).
            %
            %   result = ae.SpikesByTrial.spikeCountStruct(relvar, win, field1, field2, ...)
            %   fetches additional non-key fields from relvar.
            result = fetch(relvar, 'spikes_by_trial', varargin{:});
            counts = cellfun(@(x) sum(x > win(1) & x < win(2)), {result.spikes_by_trial}, 'UniformOutput', false);
            [result.spike_count] = deal(counts{:});
            result = rmfield(result, 'spikes_by_trial');
        end
    end
end
