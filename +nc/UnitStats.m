%{
nc.UnitStats (computed) # Several summary stats for units

-> nc.UnitStatsSet
-> ephys.Spikes
---
mean_rate        : float    # average firing rate
mean_count       : float    # mean spike count
mean_var         : float    # average variance
mean_fano = NULL : float    # average fano factor
stability        : float    # stability measure
%}

classdef UnitStats < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.UnitStats');
    end
    
    methods 
        function self = UnitStats(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            
            tuple = key;
            
            % Stability score: correlation (over trials) between spike
            % counts in different conditions. If the overall activity of a
            % neuron fluctuates slowly over time these will be positive. A
            % stable neuron's stability score will be close to zero.
            %
            % To get maximal power in detecting instabilities we use a
            % large window to count spikes (including fixation)
            stimTime = fetch1(nc.Gratings(key), 'stimulus_time');
            rel = (ae.SpikesByTrial(key) & stimulation.StimTrials('valid_trial = true')) * nc.GratingTrials(key);
            nCond = count(stimulation.StimConditions(key));
            minTrials = fix(count(rel) / nCond);
            spikes = ae.SpikesByTrial.spikeCountStruct(rel, [-300, stimTime], 'condition_num', minTrials * nCond);
            spikes = dj.struct.sort(spikes, 'condition_num');
            counts = reshape([spikes.spike_count], [], nCond);
            R = corrcoef(counts);
            tuple.stability = nanmean(R(~tril(ones(size(R)))));
            if isnan(tuple.stability) % i.e. no spikes at all
                tuple.stability = 1;
            end
            
            % Mean firing rates and variances. Here we use the window of
            % interest for the analysis, defined by the SpikeCounts table
            trials = validTrialsCompleteBlocks(nc.Gratings(key));
            nCond = count(nc.GratingConditions(key));
            data = fetch(ae.SpikeCounts(key) * trials, 'spike_count', 'condition_num');
            data = dj.struct.sort(data, 'condition_num');
            counts = reshape([data.spike_count], [], nCond);
            tuple.mean_count = mean(counts(:));
            tuple.mean_var = mean(var(counts, [], 1));
            tuple.mean_fano = mean(var(counts, [], 1) ./ mean(counts, 1));
            tuple.mean_rate = tuple.mean_count / (key.spike_count_end - key.spike_count_start) * 1000;
            self.insert(tuple);
        end
    end
end
