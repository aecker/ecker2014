%{
nc.LnpModelSet (computed) # Firing rate prediction from LFP

-> nc.Gratings
-> ae.SpikesByTrialSet
-> cont.Lfp
-> nc.PsthBasis
---
%}

classdef LnpModelSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.LnpModelSet');
        popRel = nc.PsthBasis('use_log = false and use_zscores = true') * ...
            cont.Lfp * nc.Gratings * ae.SpikesByTrialSet;
    end
    
    methods 
        function self = LnpModelSet(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(this, key)
            insert(this, key);
            for unitKey = fetch((this.popRel & key) * ephys.Spikes)'
                fprintf('Unit %d\n', unitKey.unit_id)
                makeTuples(nc.LnpModel, unitKey);
            end
        end
    end
end
