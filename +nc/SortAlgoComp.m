%{
nc.SortAlgoComp (computed) # Comparing spike sorting algorithms

-> nc.SortAlgoCompSet
-> sort.KalmanUnits
compare_to_number   : tinyint unsigned  # unit number to compare to
---
hits                : float             # percent hits
missed_by1          : float             # percent misses
missed_by2          : float             # percent false positives
num_spikes1         : int               # number of spikes unit 1
num_spikes2         : int               # number of spikes unit 2
%}


classdef SortAlgoComp < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.SortAlgoComp');
    end
    
    methods 
        function self = SortAlgoComp(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            maxOffset = 0.5;
            unitsMoG = fetch(sort.TetrodesMoGLink(rmfield(key, 'sort_method_num')));
            unitsMoKsm = fetch(sort.KalmanLink(key));
            for unitMoKsm = unitsMoKsm'
                ti = fetch1(ephys.Spikes(unitMoKsm), 'spike_times');
                for unitMoG = unitsMoG'
                    tj = fetch1(ephys.Spikes(unitMoG), 'spike_times');
                    tuple = key;
                    tuple.cluster_number = unitMoKsm.cluster_number;
                    tuple.compare_to_number = unitMoG.cluster_number;
                    tuple.hits = 0;
                    tuple.missed_by1 = 0;
                    tuple.missed_by2 = 0;
                    tuple.num_spikes1 = numel(ti);
                    tuple.num_spikes2 = numel(tj);
                    j = 1;
                    for i = 1 : tuple.num_spikes1
                        while j <= tuple.num_spikes2 && tj(j) < ti(i) - maxOffset
                            j = j + 1;
                            tuple.missed_by1 = tuple.missed_by1 + 1;
                        end
                        if j <= tuple.num_spikes2 && tj(j) < ti(i) + maxOffset
                            tuple.hits = tuple.hits + 1;
                        else
                            tuple.missed_by2 = tuple.missed_by2 + 1;
                        end
                    end
                    tuple.missed_by1 = tuple.missed_by1 + (tuple.num_spikes2 - j - tuple.hits + 1);
                    self.insert(tuple);
                end
            end
        end
    end
end
