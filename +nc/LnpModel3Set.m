%{
nc.LnpModel3Set (computed) # Firing rate prediction from LFP

-> nc.Gratings
-> ae.SpikesByTrialSet
-> ae.LfpSet
---
bin_size        : double        # bin size
min_trials      : int unsigned  # minimum number of trials per condition
%}

classdef LnpModel3Set < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.LnpModel3Set');
        popRel = nc.Gratings * ae.LfpSet * ae.SpikesByTrialSet;
    end
    
    methods 
        function self = LnpModel3Set(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            
            tuple = key;
            tuple.bin_size = 1000 / (key.max_freq * 2);
            tuple.min_trials = min(fetchn(nc.Gratings * nc.GratingConditions & key, ...
                nc.GratingTrials, 'count(1) -> n'));
            self.insert(tuple);
            
            % LFP data
            for lfpKey = fetch((self & key) * ae.Lfp)'
                makeTuples(nc.LnpModel3Lfp, lfpKey)
            end
            
            % spike data
            for spikeKey = fetch((self & key) * ephys.Spikes)'
                makeTuples(nc.LnpModel3Spikes, spikeKey)
            end
            
            % child table nc.LnpModel3 is AutoPopulate as well so I can
            % parallelize it on the cluster. This is an exception to the
            % usual DJ rules
        end
    end
end
