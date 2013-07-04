%{
nc.NoiseCorrelationSet (computed) # Set of all noise correlations

-> nc.UnitPairSet
-> ae.SpikeCountSet
-> nc.OriTuningSet
-> nc.Gratings
-> nc.UnitStatsSet
---
%}

classdef NoiseCorrelationSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.NoiseCorrelationSet');
        popRel = (nc.UnitPairSet * ae.SpikeCountSet * nc.OriTuningSet * nc.Gratings * nc.UnitStatsSet) ...
            & 'stimulus_time + 30 >= spike_count_end';
    end

    methods(Access = protected)
        function makeTuples(self, key)
            self.insert(key);
            
            % get trials, conditions, pairs, etc.
            condKeys = fetch(nc.GratingConditions & key);
            nCond = numel(condKeys);
            pairKeys = fetch(nc.UnitPairs & key);
            nPairs = numel(pairKeys);
            nUnits = count(ephys.Spikes & key);
            unitIds = fetchn(nc.UnitPairs * nc.UnitPairMembership & key, 'unit_id', 'ORDER BY pair_num');
            unitIds = reshape(unitIds, 2, []);
            counts = fetchn(ae.SpikeCounts & key, 'spike_count', 'ORDER BY unit_id, trial_num');
            counts = reshape(counts, [], nUnits);
            cond = fetchn(nc.GratingTrials * stimulation.StimTrials & key & 'valid_trial = true', 'condition_num', 'ORDER BY trial_num');
            
            % compute noise correlations and z-scores for each condition
            r = zeros(nCond, nPairs);
            rates = zeros(nCond, nUnits);
            z = counts;
            for iCond = 1 : nCond
                ndx = (cond == iCond);
                R = corrcoef(counts(ndx, :));
                z(ndx, :) = zscore(counts(ndx, :), 1, 1);
                for iPair = 1 : nPairs
                    r(iCond, iPair) = R(unitIds(1, iPair), unitIds(2, iPair));
                end
                rates(iCond, :) = mean(counts(ndx, :), 1);
            end
            duration = key.spike_count_end - key.spike_count_start;
            rates = rates / duration * 1000;
            
            % high-pass filter z-scores
            [b, a] = butter(5, 1 / 50, 'high');
            Rf = corrcoef(filtfilt(b, a, z));
            
            % summary statistics for the cells
            highContrast = fetch1(nc.OriTuning & key, 'max(contrast) -> c');
            if strcmp(fetch1(sort.Methods & key, 'sort_method_name'), 'MultiUnit')
                rel = ephys.Spikes * ae.TetrodeProperties * nc.OriTuning * nc.UnitStats;
                [x, y, pref, instab] = fetchn(rel & key & struct('contrast', highContrast), ...
                    'loc_x', 'loc_y', 'pref_ori', 'tac_instability', 'ORDER BY unit_id');
                contam = zeros(size(x));
            else
                rel = ephys.Spikes * ephys.SingleUnit * ae.TetrodeProperties * nc.OriTuning * nc.UnitStats;
                [x, y, pref, instab, contam] = fetchn(rel & key & struct('contrast', highContrast), ...
                    'loc_x', 'loc_y', 'pref_ori', 'tac_instability', 'fp + fn -> c', 'ORDER BY unit_id');
            end
            
            for iPair = find(~all(isnan(r)))
                key.pair_num = pairKeys(iPair).pair_num;
                ui = unitIds(1, iPair);
                uj = unitIds(2, iPair);
                
                tuple = key;
                tuple.r_noise_avg = nanmean(r(:, iPair));
                tuple.r_noise_filt = Rf(ui, uj);
                tuple.geom_mean_rate = mean(sqrt(prod(rates(:, unitIds(:, iPair)), 2)));
                tuple.min_rate = mean(min(rates(:, unitIds(:, iPair)), [], 2));
                tuple.diff_pref_ori = abs(angle(exp(2i * diff(pref(unitIds(:, iPair)))))) / 2;
                tuple.r_signal = corr(rates(:, ui), rates(:, uj));
                tuple.distance = sqrt(diff(x(unitIds(:, iPair))) .^ 2 + diff(y(unitIds(:, iPair))) .^ 2);
                tuple.instab = max(instab(ui), instab(uj));
                tuple.contam = max(contam(ui), contam(uj));

                % trial cross-correlogram (TCC)
                k = 20;
                tcc = xcorr(z(:, ui), z(:, uj), k, 'unbiased');
                win = gausswin(2 * k + 1);
                win(k + 1) = 0;
                win = win / sum(win);
                tuple.tcc = (tcc(k + 1 - (0 : k)) + tcc(k + 1 + (0 : k))) / 2;
                tuple.r_lt = tcc' * win;
                tuple.r_st = tcc(k + 1) - tuple.r_lt;
                
                insert(nc.NoiseCorrelations, tuple)

                % per condition
                for iCond = 1 : nCond
                    tuple = key;
                    tuple.condition_num = condKeys(iCond).condition_num;
                    tuple.r_noise_cond = r(iCond, iPair);
                    tuple.geom_mean_rate_cond = sqrt(prod(rates(iCond, unitIds(:, iPair))));
                    tuple.min_rate_cond = min(rates(iCond, unitIds(:, iPair)));
                    insert(nc.NoiseCorrelationConditions, tuple)
                end
            end
        end
    end
end


function m = nanmean(x)
    m = mean(x(~isnan(x)));
end
