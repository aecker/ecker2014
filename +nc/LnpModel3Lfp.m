%{
nc.LnpModel3Lfp (computed) # LFP data for LNP model

-> nc.LnpModel3Set
-> ae.Lfp
-> nc.GratingConditions
---
lfp_data        : longblob      # filtered LFP
%}

classdef LnpModel3Lfp < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.LnpModel3Lfp');
    end
    
    methods 
        function self = LnpModel3Lfp(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            
            [lfp, t0, Fs] = fetch1(ae.Lfp(key), 'lfp', 'lfp_t0', 'lfp_sampling_rate');
            binSize = 1000 / Fs;
            
            % determine trials to use (equal number per condition)
            validTrials = validTrialsCompleteBlocks(nc.Gratings(key));

            % trials & conditions
            trials = fetch(validTrials * nc.GratingConditions, 'condition_num');
            trials = dj.struct.sort(trials, 'trial_num');
            conditions = [trials.condition_num];
            showStim = sort(double(fetchn(stimulation.StimTrialEvents(validTrials) & 'event_type = "showStimulus"', 'event_time')));
            
            nTrials = numel(trials);
            nCond = numel(unique(conditions));
            nBins = fix(fetch1(nc.Gratings(key), 'stimulus_time') / binSize);

            % extract lfp for each trial
            trialLfp = zeros(nBins, nTrials / nCond, nCond);
            for iTrial = 1 : nTrials
                iBlock = ceil(iTrial / nCond);
                first = (showStim(iTrial) - t0) / binSize + 0.5; % sample at the first bin center
                bins = fix(first) + (0 : nBins);
                t = t0 + bins * binSize;
                ti = t0 + (first + (0 : nBins - 1)) * binSize;
                trialLfp(:, iBlock, conditions(iTrial)) = interp1(t, lfp(bins + 1), ti, 'cubic');
            end
            
            % subtract stimulus-evoked LFP component
            trialLfp = bsxfun(@minus, trialLfp, mean(trialLfp, 2));
            
            for iCond = 1 : nCond
                tuple = key;
                tuple.condition_num = iCond;
                tuple.lfp_data = trialLfp(:, :, iCond);
                self.insert(tuple);
            end
        end
    end
end
