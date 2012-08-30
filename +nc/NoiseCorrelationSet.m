%{
nc.NoiseCorrelationSet (computed) # Set of all noise correlations

-> nc.UnitPairSet
-> ae.SpikeCountSet
-> nc.Gratings
---
%}

classdef NoiseCorrelationSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.NoiseCorrelationSet');
        popRel = nc.UnitPairSet * ae.SpikeCountSet;
    end
    
    methods 
        function self = NoiseCorrelationSet(varargin)
            self.restrict(varargin{:})
        end
    end

    methods(Access = protected)
        function makeTuples(this, key)
            insert(this, key);
            
            % compute noise correlations for all pairs and conditions
            condKeys = fetch(nc.GratingConditions(key));
            nCond = numel(condKeys);
            pairKeys = fetch(nc.UnitPairs(key));
            nPairs = numel(pairKeys);
            r = zeros(nCond, nPairs);
            for i = 1 : nCond
                fprintf('Condition %d\n', i)
                scTuples = fetch(ae.SpikeCounts(key) & nc.GratingTrials(condKeys(i)), 'spike_count');
                scTuples = dj.struct.sort(scTuples, {'unit_id', 'trial_num'});
                nUnits = scTuples(end).unit_id;
                spikeCounts = reshape([scTuples.spike_count], [], nUnits);
                R = corrcoef(spikeCounts);
                for j = 1 : nPairs
                    unitIds = fetchn(nc.UnitPairMembership(pairKeys(j)), 'unit_id');
                    r(i, j) = R(unitIds(1), unitIds(2));
                end
            end
            
            for j = 1 : nPairs
                key.pair_num = pairKeys(j).pair_num;
                
                % average across conditions
                tuple = key;
                tuple.r_noise_avg = nanmean(r(:, j));
                insert(nc.NoiseCorrelations, tuple)

                % per condition
                for i = 1 : nCond
                    tuple = key;
                    tuple.condition_num = condKeys(i).condition_num;
                    tuple.r_noise_cond = r(i, j);
                    insert(nc.NoiseCorrelationConditions, tuple)
                end
            end
        end
    end
end
