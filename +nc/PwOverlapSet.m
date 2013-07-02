%{
nc.PwOverlapSet (computed) # Pairwise cluster overlap

-> nc.UnitPairSet
-> ephys.SpikeSet
---
%}

classdef PwOverlapSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.PwOverlapSet');
        popRel = nc.UnitPairSet * ephys.SpikeSet * sort.Methods & 'sort_method_name = "MoKsm"';
    end
    
    methods 
        function self = PwOverlapSet(varargin)
            self.restrict(varargin{:})
        end
    end

    methods (Access = protected)
        function makeTuples(this, key)
            insert(this, key);
            for k = fetch(sort.KalmanFinalize & key)'
                model = fetch1(sort.KalmanFinalize & k, 'final_model');
                model = MoKsmInterface(model);
                pairwise = model.ContaminationMatrix.data.pairwise;
                n = model.ContaminationMatrix.data.n;
                excludePairs = nc.UnitPairs & (nc.UnitPairMembership * ephys.Spikes & key & sprintf('electrode_num <> %d', k.electrode_num));
                [cl, pairKeys] = fetchn((nc.UnitPairs * nc.UnitPairMembership * ephys.Spikes * sort.KalmanLink & k) - excludePairs, 'cluster_number', 'ORDER BY pair_num, cluster_number ASC');
                pairKeys = rmfield(pairKeys(1 : 2 : end), {'unit_id', 'electrode_num', 'cluster_number'});
                cl = reshape(cl, 2, []);
                nPairs = numel(pairKeys);
                for i = 1 : nPairs
                    ndxi = model.GroupingAssignment.data{cl(1, i)};
                    ndxj = model.GroupingAssignment.data{cl(2, i)};
                    ci = sum(sum(pairwise(ndxi, ndxj))) / sum(n(ndxj));
                    cj = sum(sum(pairwise(ndxj, ndxi))) / sum(n(ndxi));
                    ca = (sum(sum(pairwise(ndxi, ndxj))) + sum(sum(pairwise(ndxj, ndxi)))) / sum(n([ndxi ndxj]));
                    tuple = pairKeys(i);
                    tuple.min_contam = min(ci, cj);
                    tuple.max_contam = max(ci, cj);
                    tuple.avg_contam = ca;
                    insert(nc.PwOverlap, tuple);
                end
            end
        end
    end
end
