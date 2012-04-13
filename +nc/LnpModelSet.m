%{
nc.LnpModelSet (computed) # Firing rate prediction from LFP

-> nc.Gratings
-> ae.SpikesByTrialSet
-> ae.LfpByTrialSet
-> nc.LnpModelParams
---
%}

classdef LnpModelSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.LnpModelSet');
        popRel = nc.Gratings * ae.SpikesByTrialSet * ae.LfpByTrialSet * nc.LnpModelParams;
    end
    
    methods 
        function self = LnpModelSet(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(this, key)
            insert(this, key);
            for unitKey = fetch((this.popRel & key) * ephys.Spikes)'
                fprintf('Unit %d\n', unitKey.unit_id)
                makeTuples(nc.LnpModel, unitKey);
            end
        end
    end
end
