%{
nc.PsthSet (computed) # Set of PSTHs
-> ephys.SpikeSet
-> nc.Gratings

-----

%}

classdef PsthSet < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('nc.PsthSet')
		popRel = ephys.SpikeSet * nc.Gratings
	end

	methods
		function self = PsthSet(varargin)
			self.restrict(varargin)
        end
    end
    
    methods (Access = protected)
		function makeTuples(self, key)

            self.insert(key)
		end
	end
end
