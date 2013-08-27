%{
nc.AnalysisStims (computed) # Stimulus sessions to use for analysis

-> nc.Gratings
-> acq.EphysStimulationLink
-> ephys.SpikeSet
-> nc.Anesthesia
-> nc.AnalysisParams
state   : enum("awake", "anesthetized")  # brain state during experiment
---
%}

classdef AnalysisStims < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.AnalysisStims');
        popRel = pro(nc.Anesthesia * nc.Gratings * nc.AnalysisParams * acq.EphysStimulationLink * ephys.SpikeSet, ...
            nc.Gratings * nc.UnitStats * nc.AnalysisParams ...
            & 'tac_instability < max_instability AND spike_count_end = stimulus_time + 30', ...
            'count(1) -> n', 'trials_per_cond', 'stimulus_time') ...
            & 'n >= 10 AND trials_per_cond >= 20 AND stimulus_time >= 500';
    end
    
    methods 
        function self = AnalysisStims(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            key.state = fetch1(nc.Anesthesia & key, 'state');
            self.insert(key);
        end
    end
end
