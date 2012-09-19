%{
nc.LnpModel2Set (computed) # Firing rate prediction from LFP

-> nc.Gratings
-> ae.SpikesByTrialSet
-> cont.Lfp
-> nc.PsthBasis
---
%}

classdef LnpModel2Set < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.LnpModel2Set');
        popRel = nc.PsthBasis('use_log = false and use_zscores = true') * ...
            cont.Lfp * nc.Gratings * ae.SpikesByTrialSet;
    end
    
    methods 
        function self = LnpModel2Set(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(this, key)
            insert(this, key);
            for unitKey = fetch((this.popRel & key) * ephys.Spikes)'
                fprintf('Unit %d\n', unitKey.unit_id)
                makeTuples(nc.LnpModel2, unitKey);
            end
        end
    end
end
