%{
ae.SpikesByTrial (computed) # Spike times organized by trials

-> ae.SpikesByTrialSet
-> ephys.Spikes
-> stimulation.StimTrials
---
spikes_by_trial = NULL : blob # Aligned spike times for one trial
%}

classdef SpikesByTrial < dj.Relvar
    properties (Constant)
        table = dj.Table('ae.SpikesByTrial');
    end
    
    methods
        function k = makeTuples(self, key, spikes, k)
            tuple = key;
            totalTrials = count(stimulation.StimTrials & rmfield(key, 'trial_num'));
            if key.trial_num < totalTrials
                switch fetch1(acq.Stimulation & key, 'exp_type')
                    case 'AcuteGratingExperiment'
                        event = 'showStimulus';
                    case {'GratingExperiment', 'mgrad', 'movgrad'}
                        event = 'startTrial';
                    otherwise
                        error('Don''t know which event to use to determine start of next trial!')
                end
                nextTrial = key;
                nextTrial.trial_num = nextTrial.trial_num + 1;
                endTrial = fetch1(stimulation.StimTrialEvents & nextTrial & ...
                    sprintf('event_type = "%s"', event), 'event_time');
            else
                endTrial = fetch1(stimulation.StimTrialEvents & key, 'max(event_time) -> t') + 2000;
            end
            showStim = fetch1(stimulation.StimTrialEvents & key & 'event_type = "showStimulus"', 'event_time');
            startTrial = showStim - fetch1(ae.SpikesByTrialSet & key, 'pre_stim_time');
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
    
    methods (Static)
        function [counts, varargout] = spikeCount(relvar, win, varargin)
            % Get spike counts.
            %   counts = ae.SpikesByTrial.spikeCount(relvar, win) returns
            %   the spike counts for each tuple in relvar. The counting
            %   window is specified by the two-element vector win (times
            %   relative to stimulus onset).
            %
            % Note that you can't rely on any particular order when using
            % this function. Use spikeCountStruct if the order of the data
            % is important.
            [spikes, varargout{1 : nargout - 1}] = fetchn(relvar, 'spikes_by_trial', varargin{:});
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
