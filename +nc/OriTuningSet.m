%{
nc.OriTuningSet (computed)          # cell statistics
-> nc.Gratings
-> ae.SpikesByTrialSet
-----
%}

classdef OriTuningSet < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('nc.OriTuningSet')
		popRel = nc.Gratings * ae.SpikesByTrialSet;
	end

	methods
		function self = OriTuningSet(varargin)
			self.restrict(varargin)
		end
    end

    methods(Access = protected)
		function makeTuples(self, key)
			insert(self, key)
            contrasts = unique(fetchn(nc.Gratings(key) * nc.GratingConditions, 'contrast'));
            for unit = fetch(ephys.Spikes(key))'
                for contrast = contrasts'
                    newKey = dj.struct.join(unit, key);
                    newKey.contrast = contrast;
                    makeTuples(nc.OriTuning, newKey);
                end
            end
		end
	end
end
