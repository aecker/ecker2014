%{
nc.Psth (computed) # PSTH for one neuron

-> nc.PsthSet
-> ephys.Spikes
-----
psth    : longblob  # psth data
%}

classdef Psth < dj.Relvar

	properties(Constant)
		table = dj.Table('nc.Psth')
	end

	methods
		function self = Psth(varargin)
			self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            trials = fetch(nc.GratingTrials(key));
            trials = dj.struct.sort(trials, 'trial_num');
            conditions = [trials.condition_num];
            showStim = sort(fetchn(stimulation.StimTrialEvents(key) & 'event_type = "showStimulus"', 'event_time'));
            endStim = sort(fetchn(stimulation.StimTrialEvents(key) & 'event_type = "endStimulus"', 'event_time'));
            spikeTimes = fetch1(ephys.Spikes(key), 'spike_times');
            spikeTimes = spikeTimes(spikeTimes > showStim(1) & spikeTimes < endStim(end) + 5000);
            nSpikes = numel(spikeTimes);
            nTrials = numel(showStim);
            nCond = count(nc.GratingConditions(key));
            nBins = fix(min(diff(showStim)) / key.bin_size);
            psth = zeros(nBins, nCond);
            binSize = key.bin_size;
            iSpike = 1;
            for iTrial = 1 : nTrials
                while iSpike <= nSpikes && spikeTimes(iSpike) < showStim(iTrial)
                    iSpike = iSpike + 1;
                end
                for iBin = 1 : nBins
                    until = showStim(iTrial) + iBin * binSize;
                    curSpike = iSpike;
                    while iSpike < nSpikes && spikeTimes(iSpike) < until
                        iSpike = iSpike + 1;
                    end
                    psth(iBin, conditions(iTrial)) = psth(iBin, conditions(iTrial)) + iSpike - curSpike;
                end
            end
            tuple = key;
            tuple.psth = psth / (nTrials / nCond);
            self.insert(tuple)
		end
	end
end
