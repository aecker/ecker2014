%{
nc.LfpPowerRatioCorr (computed) # LFP power ratio for each trial

-> nc.LfpPowerRatioStim
-> nc.UnitPairs
-> ae.SpikeCountSet
---
r_noise_low         : double    # noise correlations in low-ratio trials
r_noise_high        : double    # nc in high-ratio trials
power_ratio_low     : double    # average power ratio in lower half of trials
power_ratio_high    : double    # average power ratio in upper half of trials
%}

classdef LfpPowerRatioCorr < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.LfpPowerRatioCorr');
        popRel = nc.LfpPowerRatioStim * nc.UnitPairSet * ae.SpikeCountSet;
    end
    
    methods 
        function self = LfpPowerRatioCorr(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            
            % obtain LFP power ratios
            data = fetch(nc.GratingTrials * nc.LfpPowerRatioTrials & key, ...
                'condition_num', 'power_ratio_prctile', 'power_ratio_trial');
            data = dj.struct.sort(data, 'trial_num');
            condition = [data.condition_num];
            prctile = [data.power_ratio_prctile];
            ratio = [data.power_ratio_trial];
            
            % obtain spike counts
            nUnits = count(ephys.Spikes & key);
            data = fetch(ae.SpikeCounts & key, 'spike_count');
            data = dj.struct.sort(data, {'unit_id', 'trial_num'});
            counts = reshape([data.spike_count], [], nUnits);
            
            % convert each condition to z-scores
            nCond = count(nc.GratingConditions & key);
            for iCond = 1 : nCond
                ndx = condition == iCond;
                counts(ndx, :) = zscore(counts(ndx, :), 1);
            end

            % compute noise correlations for the low- and high-ratio trials
            Rlow = corrcoef(counts(prctile <= 0.5, :));
            Rhigh = corrcoef(counts(prctile > 0.5, :));
            
            % insert into database
            pairKeys = fetch(nc.UnitPairs & key);
            nPairs = numel(pairKeys);
            pairs = fetch(nc.UnitPairs * nc.UnitPairMembership & key);
            pairs = dj.struct.sort(pairs, 'pair_num');
            unitIds = reshape([pairs.unit_id], 2, []);
            for iPair = 1 : nPairs
                tuple = key;
                tuple.pair_num = iPair;
                tuple.r_noise_low = Rlow(unitIds(1, iPair), unitIds(2, iPair));
                tuple.r_noise_high = Rhigh(unitIds(1, iPair), unitIds(2, iPair));
                tuple.power_ratio_low = mean(ratio(prctile <= 0.5));
                tuple.power_ratio_high = mean(ratio(prctile > 0.5));
                self.insert(tuple);
            end
        end
    end
end
