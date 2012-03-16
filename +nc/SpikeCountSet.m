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
            for unitKey = fetch(ephys.Spikes(key))'
                fprintf('Unit %d\n', unitKey.unit_id)
                t = fetch1(ephys.Spikes(unitKey), 'spike_times');
                nSpikes = numel(t);
                k = 0;
                tuples = fetch(ephys.Spikes(unitKey) ...
                    * (stimulation.StimTrials(key) & 'valid_trial = true') ...
                    * nc.SpikeCountParams(key), 'start_time');
                spikeCount = cell(numel(tuples), 1);
                trial = 1;
                for tuple = tuples'
                    while k > 0 && t(k) > tuple.start_time + b
                        k = k - 1;
                    end
                    while k < nSpikes && t(k + 1) < tuple.start_time + b
                        k = k + 1;
                    end
                    k0 = k;
                    while k < nSpikes && t(k + 1) < tuple.start_time + e
                        k = k + 1;
                    end
                    spikeCount{trial} = k - k0;
                    trial = trial + 1;
                end
                tuples = rmfield(tuples, 'start_time');
                [tuples.spike_count] = deal(spikeCount{:});
                insert(nc.SpikeCounts, tuples);
            end
        end
    end
end
