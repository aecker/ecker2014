%{
nc.LfpPowerRatioStim (computed) # LFP power ratio during stimulus presentation

-> nc.LfpPowerRatioStimParams
-> cont.Lfp
-> nc.Gratings
---
power_ratio_avg     : double            # ratio of LFP power below/above split freq.
power_ratio_blocks  : mediumblob        # time-resolved ratio (blockwise)
power_low           : mediumblob        # power in low frequencies
power_high          : mediumblob        # power in high frequencies
%}

classdef LfpPowerRatioStim < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.LfpPowerRatioStim');
        popRel = cont.Lfp * acq.EphysStimulationLink * nc.Gratings * nc.LfpPowerRatioStimParams;
    end
    
    methods 
        function self = LfpPowerRatioStim(varargin)
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
            
            % determine stimulus periods
            trials = validTrialsCompleteBlocks(nc.Gratings & key);
            nCond = count(nc.GratingConditions & key);
            showStim = sort(fetchn(trials * stimulation.StimTrialEvents ...
                & 'event_type = "showStimulus"', 'event_time'));
            win = key.win_start / 1000 * Fs + 1 : key.win_end / 1000 * Fs;
            ndx = bsxfun(@plus, getSampleIndex(br, showStim), win)';
            
            % extract stimulus-triggered LFP
            lfp = zeros(numel(ndx), nTet);
            for i = 1 : nTet
                br = baseReader(lfpFile, sprintf('t%d', tet(i)));
                lfp(:, i) = br(ndx(:), 1);
            end
            lfp = reshape(median(lfp, 2), size(ndx));

            % compute power ratio
            n = numel(win);
            f = linspace(0, Fs, n);
            Pxx = abs(fft(lfp, n, 1));
            
            df = f(2) / 2;
            low = f >= key.low_min & f < key.low_max;
            high = (f >= key.high_min & f < key.high_max) & ... exclude 50 & 60 Hz (line noise)
                ~(f > 50 - df & f < 50 + df) & ~(f > 60 - df & f < 60 + df);
            Plow = mean(Pxx(low, :), 1);
            Phigh = mean(Pxx(high, :), 1);
            
            % insert into database
            tuple = key;
            tuple.power_ratio_avg = mean(Plow) / mean(Phigh);
            avgBlocks = @(x) mean(reshape(x, nCond, []), 1);
            tuple.power_ratio_blocks = avgBlocks(Plow) ./ avgBlocks(Phigh);
            tuple.power_low = Plow;
            tuple.power_high = Phigh;
            self.insert(tuple);
            
            makeTuples(nc.LfpPowerRatioTrials, key, Plow, Phigh)
        end
    end
end
