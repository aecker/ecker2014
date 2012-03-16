%{
nc.NoiseCorrelationSet (computed) # Set of all noise correlations

-> nc.UnitPairSet
-> nc.SpikeCountSet
-> nc.Gratings
---
%}

classdef NoiseCorrelationSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.NoiseCorrelationSet');
        popRel = nc.UnitPairSet * nc.SpikeCountSet;
    end
    
    methods 
        function self = NoiseCorrelationSet(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(this, key)
            insert(this, key);
            
            condKeys = fetch(nc.GratingConditions(key));
            nCond = numel(condKeys);
            pairKeys = fetch(nc.UnitPairs(key));
            nPairs = numel(pairKeys);
            r = zeros(nCond, nPairs);
            for i = 1:nCond
                fprintf('Condition %d\n', i)
                scTuples = fetch(nc.SpikeCounts(key) & nc.GratingTrials(condKeys(i)), 'spike_count');
                scTuples = dj.struct.sort(scTuples, {'unit_id', 'trial_num'});
                nUnits = scTuples(end).unit_id;
                spikeCounts = reshape([scTuples.spike_count], [], nUnits);
                R = corrcoef(spikeCounts);
                for j = 1:nPairs
                    unitIds = fetchn(nc.UnitPairMembership(pairKeys(j)), 'unit_id');
                    r(i, j) = R(unitIds(1), unitIds(2));
                end
            end
            
            tuples = dj.struct.join(pairKeys, key);
            for j = 1:nPairs
                tuples(j).r_noise_cond = r(:, j);
                tuples(j).r_noise_avg = nanmean(r(:, j));
            end
            insertfast(nc.NoiseCorrelations, tuples)
        end
    end
end
