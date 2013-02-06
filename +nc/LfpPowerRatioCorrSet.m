%{
nc.LfpPowerRatioCorrSet (computed) # Correlation between LFP and NC

-> cont.Lfp
-> nc.Gratings
-> ae.SpikeCountSet
-> nc.LfpPowerRatioCorrParams
---
power_ratio_avg     : double            # LFP power ratio
%}

classdef LfpPowerRatioCorrSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.LfpPowerRatioCorrSet');
        popRel = cont.Lfp * ae.SpikeCountSet * nc.Gratings * nc.LfpPowerRatioCorrParams ...
            & 'subject_id IN (9, 11) AND sort_method_num = 5 AND spike_count_end = 2030';
    end
    
    methods 
        function self = LfpPowerRatioCorrSet(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)

            % determine available tetrodes etc.
            tet = fetchn(detect.Electrodes & key, 'electrode_num');
            nTet = numel(tet);
            lfpFile = getLocalPath(fetch1(cont.Lfp & key, 'lfp_file'));
            br = baseReader(lfpFile, sprintf('t%d', tet(1)));
            Fs = getSamplingRate(br);
            
            % determine blocks
            trials = validTrialsCompleteBlocks(nc.Gratings & key);
            showStim = sort(fetchn(trials * stimulation.StimTrialEvents ...
                & 'event_type = "showStimulus"', 'event_time'));
            endStim = sort(fetchn(trials * stimulation.StimTrialEvents ...
                & 'event_type = "endStimulus"', 'event_time'));
            nTrials = numel(showStim);
            nBlocks = key.num_blocks;
            nTrialsPerBlock = fix(nTrials / nBlocks);
            blocks = [showStim((0 : nBlocks - 1) * nTrialsPerBlock + 1), ...
                      endStim((1 : nBlocks) * nTrialsPerBlock)];
            blocks = getSampleIndex(br, blocks);
            
            % extract LFP & compute power spectra
            n = 2^13;
            Pxx = zeros(n + 1, nBlocks, nTet);
            for iTet = 1 : nTet
                br = baseReader(lfpFile, sprintf('t%d', tet(iTet)));
                for iBlock = 1 : nBlocks
                    lfp = br(blocks(iBlock, 1) : blocks(iBlock, 2), 1);
                    Pxx(:, iBlock, iTet) = pwelch(lfp, 2 * n);
                end
            end
            f = linspace(0, Fs / 2, n + 1);
            df = f(2) / 2;
            low = f > key.low_min & f < key.low_max;
            high = (f > key.high_min & f < key.high_max) & ... exclude 50 & 60 Hz (line noise)
                ~(f > 50 - df & f < 50 + df) & ~(f > 60 - df & f < 60 + df);
            ratio = mean(Pxx(low, :, :), 1) ./ mean(Pxx(high, :, :), 1);
            ratio = mean(log2(ratio), 3);
            rank = tiedrank(ratio);
                        
            % obtain spike counts
            data = fetch(nc.GratingTrials & key, 'condition_num');
            data = dj.struct.sort(data, 'trial_num');
            condition = [data.condition_num];
            nUnits = count(ephys.Spikes & key);
            data = fetch(ae.SpikeCounts & key, 'spike_count');
            data = dj.struct.sort(data, {'unit_id', 'trial_num'});
            counts = reshape([data.spike_count], [], nUnits);

            % compute noise correlations
            nCond = count(nc.GratingConditions & key);
            R = zeros(nUnits, nUnits, nBlocks);
            for iBlock = 1 : nBlocks
                ndx = (iBlock - 1) * nTrialsPerBlock + (1 : nTrialsPerBlock);
                blockCounts = counts(ndx, :);
                blockCond = condition(ndx);
                for iCond = 1 : nCond % z-scores for each condition and block
                    ndx = blockCond == iCond;
                    blockCounts(ndx, :) = zscore(blockCounts(ndx, :), 1);
                end
                R(:, :, iBlock) = corrcoef(blockCounts);
            end
            pairKeys = fetch(nc.UnitPairs & key);
            nPairs = numel(pairKeys);
            pairs = fetch(nc.UnitPairs * nc.UnitPairMembership & key);
            pairs = dj.struct.sort(pairs, 'pair_num');
            unitIds = reshape([pairs.unit_id], 2, []);
          
            % insert into database
            set = key;
            set.power_ratio_avg = mean(ratio);
            self.insert(set);
            for iBlock = 1 : nBlocks
                block = key;
                block.block_num = iBlock;
                block.power_ratio = ratio(iBlock);
                block.delta_power_ratio = block.power_ratio - set.power_ratio_avg;
                block.block_rank = rank(iBlock);
                insert(nc.LfpPowerRatioCorr, block);
                for iPair = 1 : nPairs
                    pair = key;
                    pair.block_num = iBlock;
                    pair.pair_num = iPair;
                    pair.r_noise = R(unitIds(1, iPair), unitIds(2, iPair), iBlock);
                    pair.delta_r_noise = pair.r_noise - mean(R(unitIds(1, iPair), unitIds(2, iPair), :));
                    insert(nc.LfpPowerRatioCorrPairs, pair);
                end
            end
        end
    end
end
