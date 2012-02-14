%{
nc.SpikeCountSet (computed) # Spike counts

-> acq.StimulationSyncDiode
-> ephys.SpikeSet
-> stimulation.StimTrialGroup
-> nc.SpikeCountParams
---
%}

classdef SpikeCountSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.SpikeCountSet');
        popRel = (acq.StimulationSyncDiode & (ae.ProjectsStimulation * nc.SpikeCountProjects)) ...
            * ephys.SpikeSet * stimulation.StimTrialGroup * nc.SpikeCountParams;
    end
    
    methods 
        function self = SpikeCountSet(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            insert(self, key);
            b = key.spike_count_start;
            e = key.spike_count_end;
            [unitId, spikeTimes] = fetchn(ephys.Spikes(key), 'unit_id', 'spike_times');
            [trialNum, startTime] = fetchn(stimulation.StimTrials(key) & 'valid_trial = true', 'trial_num', 'start_time');
            nTrials = numel(trialNum);
            for i = 1:numel(unitId)
                fprintf('Unit %d\n', unitId(i))
                t = spikeTimes{i};
                nSpikes = numel(t);
                k = 0;
                spikeCount = zeros(nTrials, 1);
                for j = 1:numel(trialNum)
                    while k > 0 && t(k) > startTime(j) + b
                        k = k - 1;
                    end
                    while k < nSpikes && t(k + 1) < startTime(j) + b
                        k = k + 1;
                    end
                    k0 = k;
                    while k < nSpikes && t(k + 1) < startTime(j) + e
                        k = k + 1;
                    end
                    spikeCount(j) = k - k0;
                end
                key.unit_id = unitId(i);
                trials = struct('trial_num', num2cell(trialNum), 'spike_count', num2cell(spikeCount));
                tuples = dj.utils.structJoin(key, trials);
                insert(nc.SpikeCounts, tuples);
            end
        end
    end
end
