%{
nc.PsthSet (computed) # Set of PSTHs

-> ephys.SpikeSet
-> nc.Gratings
-> nc.PsthParams
-----
%}

classdef PsthSet < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('nc.PsthSet')
		popRel = acq.StimulationSyncDiode * ephys.SpikeSet * nc.Gratings * nc.PsthParams
	end

	methods
		function self = PsthSet(varargin)
			self.restrict(varargin)
        end
    end
    
    methods (Access = protected)
		function makeTuples(self, key)
            self.insert(key)
            for unitKey = fetch((self.popRel & key) * ephys.Spikes)'
                fprintf('Unit %d\n', unitKey.unit_id)
                makeTuples(nc.Psth, unitKey);
            end
		end
	end
end
