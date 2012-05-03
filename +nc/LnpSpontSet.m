%{
nc.LnpSpontSet (computed) # Firing rate prediction from LFP

-> stimulation.StimTrialGroup
-> ephys.SpikeSet
-> cont.Lfp
---
%}

classdef LnpSpontSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.LnpSpontSet');
        popRel = stimulation.StimTrialGroup * ephys.SpikeSet * cont.Lfp;
    end
    
    methods 
        function self = LnpSpontSet(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            self.insert(key);
            for unitKey = fetch((self.popRel & key) * ephys.Spikes)'
                fprintf('Unit %d\n', unitKey.unit_id)
                makeTuples(nc.LnpSpont, unitKey);
            end
        end
    end
end
