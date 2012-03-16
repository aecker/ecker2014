%{
nc.SpikeCounts (computed) # Spike counts

-> nc.SpikeCountSet
-> ephys.Spikes
-> stimulation.StimTrials
---
spike_count : int # number of spikes in counting window
%}

classdef SpikeCounts < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.SpikeCounts');
    end
    
    methods 
        function self = SpikeCounts(varargin)
            self.restrict(varargin{:})
        end
    end
end
