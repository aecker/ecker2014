%{
nc.LnpModel3Spikes (computed) # Spike counts for LNP model

-> nc.LnpModel3Set
-> ephys.Spikes
-> nc.GratingConditions
---
spike_data      : longblob      # binned spikes
mean_rate       : double        # mean firing rate
%}

classdef LnpModel3Spikes < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.LnpModel3Spikes');
    end
    
    methods 
        function self = LnpModel3Spikes(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            
            binSize = fetch1(nc.LnpModel3Set(key), 'bin_size');
            
            % determine trials to use (equal number per condition)
            validTrials = validTrialsCompleteBlocks(nc.Gratings(key));

            % get spikes
            showStim = sort(fetchn(stimulation.StimTrialEvents(validTrials) & 'event_type = "showStimulus"', 'event_time'));
            spikeTimes = fetch1(ephys.Spikes(key), 'spike_times');
            spikeTimes = spikeTimes(spikeTimes > showStim(1) & spikeTimes < showStim(end) + 5000);
            
            % trials & conditions
            trials = fetch(validTrials * nc.GratingConditions, 'condition_num');
            trials = dj.struct.sort(trials, 'trial_num');
            conditions = [trials.condition_num];
            
            nSpikes = numel(spikeTimes);
            nTrials = numel(trials);
            nCond = numel(unique(conditions));
            nBins = fix(fetch1(nc.Gratings(key), 'stimulus_time') / binSize);

            % compute spike counts per bin
            trialSpikes = zeros(nBins, nTrials / nCond, nCond);
            iSpike = 1;
            for iTrial = 1 : nTrials
                iBlock = ceil(iTrial / nCond);
                while iSpike <= nSpikes && spikeTimes(iSpike) < showStim(iTrial)
                    iSpike = iSpike + 1;
                end
                for iBin = 1 : nBins
                    until = showStim(iTrial) + iBin * binSize;
                    curSpike = iSpike;
                    while iSpike < nSpikes && spikeTimes(iSpike) < until
                        iSpike = iSpike + 1;
                    end
                    trialSpikes(iBin, iBlock, conditions(iTrial)) = iSpike - curSpike;
                end
            end
            
            % insert into database
            for iCond = 1 : nCond
                tuple = key;
                tuple.condition_num = iCond;
                tuple.spike_data = trialSpikes(:, :, iCond);
                tuple.mean_rate = mean(tuple.spike_data(:)) / binSize * 1000;
                self.insert(tuple);
            end
        end
    end
end
