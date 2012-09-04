%{
nc.UnitStats (computed) # Several summary stats for units

-> nc.UnitStatsSet
-> ephys.Spikes
---
mean_rate       : float    # average firing rate
stability       : float    # stability measure
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
            % neurons fluctuates slowly over time these will be positive. A
            % stable neuron's stability score will be close to zero.
            %
            % To get maximal power in detecting instabilities we use a
            % large window to count spikes (including fixation/intertrial)
            stimTime = fetch1(nc.Gratings(key), 'stimulus_time');
            preStimTime = fetch1(ae.SpikesByTrialSet(key), 'pre_stim_time');
            rel = (ae.SpikesByTrial(key) & stimulation.StimTrials('valid_trial = true')) * nc.GratingTrials(key);
            nCond = count(stimulation.StimConditions(key));
            minTrials = fix(count(rel) / nCond);
            spikes = ae.SpikesByTrial.spikeCountStruct(rel, [-preStimTime, stimTime], 'condition_num', minTrials * nCond);
            spikes = dj.struct.sort(spikes, 'condition_num');
            counts = reshape([spikes.spike_count], [], nCond);
            R = corrcoef(counts);
            tuple.stability = nanmean(R(~tril(ones(size(R)))));
            
            % Mean firing rate. Here we use the window of interest for the
            % analysis, defined by the SpikeCounts table
            counts = fetchn(ae.SpikeCounts(key), 'spike_count');
            tuple.mean_rate = mean(counts) / (key.spike_count_end - key.spike_count_start) * 1000;
            
            self.insert(tuple);
        end
    end
end
