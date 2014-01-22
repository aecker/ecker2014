%{
nc.GpfaUnits (computed) # Units used for GPFA model

-> nc.GpfaModelSet
-> ephys.Spikes
---
%}

classdef GpfaUnits < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.GpfaUnits');
    end

    methods
        function self = GpfaUnits(varargin)
            self.restrict(varargin{:})
        end
        
        function fill(self, varargin)
            for key = fetch(nc.GpfaModelSet & varargin, 'unit_ids')'
                for unitId = key.unit_ids'
                    tuple = rmfield(key, 'unit_ids');
                    tuple.unit_id = unitId;
                    self.inserti(tuple);
                end
            end
        end
    end
end
