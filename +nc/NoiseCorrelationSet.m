%{
nc.NoiseCorrelationSet (computed) # Set of all noise correlations

-> nc.UnitPairSet
-> ae.SpikeCountSet
-> nc.Gratings
---
%}

classdef NoiseCorrelationSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.NoiseCorrelationSet');
        popRel = nc.UnitPairSet * ae.SpikeCountSet;
    end
    
    methods 
        function self = NoiseCorrelationSet(varargin)
            self.restrict(varargin{:})
        end
    end

    methods(Access = protected)
        function makeTuples(this, key)
            insert(this, key);
            
            % compute noise correlations for all pairs and conditions
            condKeys = fetch(nc.GratingConditions(key));
            nCond = numel(condKeys);
            pairKeys = fetch(nc.UnitPairs(key));
            nPairs = numel(pairKeys);
            nUnits = count(ephys.Spikes(key));
            r = zeros(nCond, nPairs);
            rates = zeros(nCond, nUnits);
            pairs = fetch(nc.UnitPairs(key) * nc.UnitPairMembership);
            pairs = dj.struct.sort(pairs, 'pair_num');
            unitIds = reshape([pairs.unit_id], 2, []);
            for iCond = 1 : nCond
                scTuples = fetch(ae.SpikeCounts(key) & nc.GratingTrials(condKeys(iCond)), 'spike_count');
                scTuples = dj.struct.sort(scTuples, {'unit_id', 'trial_num'});
                spikeCounts = reshape([scTuples.spike_count], [], nUnits);
                R = corrcoef(spikeCounts);
                for iPair = 1 : nPairs
                    r(iCond, iPair) = R(unitIds(1, iPair), unitIds(2, iPair));
                end
                rates(iCond, :) = mean(spikeCounts, 1);
            end
            rates = rates / fetch1(nc.Gratings(key), 'stimulus_time') * 1000;
            
            % summary statistics for the cells
            stats = fetch(ephys.Spikes(key) * ae.TetrodeProperties * nc.OriTuning, ...
                'loc_x', 'loc_y', 'pref_ori');
            stats = dj.struct.sort(stats, 'unit_id');
            x = [stats.loc_x];
            y = [stats.loc_y];
            pref = [stats.pref_ori];
            
            for iPair = 1 : nPairs
                key.pair_num = pairKeys(iPair).pair_num;
                
                tuple = key;
                tuple.r_noise_avg = nanmean(r(:, iPair));
                tuple.geom_mean_rate = mean(sqrt(prod(rates(:, unitIds(:, iPair)), 2)));
                tuple.min_rate = mean(min(rates(:, unitIds(:, iPair)), [], 2));
                tuple.diff_pref_ori = abs(angle(exp(2i * diff(pref(unitIds(:, iPair)))))) / 2;
                tuple.r_signal = corr(rates(:, unitIds(1, iPair)), rates(:, unitIds(2, iPair)));
                if isnan(tuple.r_signal) % i.e. at least one cell no spikes
                    tuple.r_signal = 0;
                end
                tuple.distance = sqrt(diff(x(unitIds(:, iPair))) .^ 2 + diff(y(unitIds(:, iPair))) .^ 2);
                
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
