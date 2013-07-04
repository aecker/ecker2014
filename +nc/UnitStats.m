%{
nc.UnitStats (computed) # Several summary stats for units

-> nc.UnitStatsSet
-> ephys.Spikes
---
mean_rate        : float    # average firing rate
mean_count       : float    # mean spike count
mean_var         : float    # average variance
mean_fano = NULL : float    # average fano factor
instability      : float    # simple stability measure
tac_instability  : float    # TAC-based statility
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
            stimTime = fetch1(nc.Gratings & key, 'stimulus_time');
            rel = ae.SpikesByTrial * stimulation.StimTrials * nc.GratingTrials & key & 'valid_trial = true';
            nCond = count(stimulation.StimConditions & key);
            [spikes, cond] = fetchn(rel, 'spikes_by_trial', 'condition_num', 'ORDER BY trial_num');
            nTrials = fix(numel(spikes) / nCond) * nCond;
            [~, order] = sort(cond(1 : nTrials));
            counts = cellfun(@(x) numel(x(x > key.spike_count_start -300 & x < stimTime)), spikes);
            if sum(counts(:))
                R = corrcoef(reshape(counts(order), [], nCond));
                tuple.instability = nanmean(R(~tril(ones(size(R)))));

                % trial autocorrelogram (TAC) to assess stability
                z = counts;
                for iCond = 1 : nCond
                    ndx = find(cond == iCond);
                    z(ndx) = zscore(z(ndx), 1);
                end
                k = 20;
                win = gausswin(2 * k + 1);
                win(k + 1) = 0;
                win = win / sum(win);
                tac = xcorr(z, k, 'coeff');
                tuple.tac_instability = tac' * win;
            else
                tuple.instability = 1;
                tuple.tac_instability = 1;
            end
                
            % Mean firing rates and variances. Here we use the window of
            % interest for the analysis, defined by the SpikeCounts table
            counts = cellfun(@(x) numel(x(x > key.spike_count_start & x < key.spike_count_end)), spikes);
            counts = reshape(counts(order), [], nCond);
            tuple.mean_count = mean(counts(:));
            tuple.mean_var = mean(var(counts, [], 1));
            tuple.mean_fano = nanmean(var(counts, [], 1) ./ mean(counts, 1));
            tuple.mean_rate = tuple.mean_count / (key.spike_count_end - key.spike_count_start) * 1000;
            self.insert(tuple);
            
            % stats by condition
            for iCond = 1 : nCond
                tuple = key;
                tuple.condition_num = iCond;
                tuple.mean_count_cond = mean(counts(:, iCond));
                tuple.var_cond = var(counts(:, iCond));
                tuple.fano_cond = tuple.var_cond / tuple.mean_count_cond;
                tuple.mean_rate_cond = tuple.mean_count_cond / (key.spike_count_end - key.spike_count_start) * 1000;
                insert(nc.UnitStatsConditions, tuple)
            end
        end
    end
end
