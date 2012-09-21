%{
nc.SortAlgoComp (computed) # Comparing spike sorting algorithms

-> nc.SortAlgoCompSet
-> sort.KalmanUnits
compare_to_number   : tinyint unsigned  # unit number to compare to
---
hits                      : float      # percent hits
missed_kalman             : float      # percent misses
missed_mog                : float      # percent false positives
num_spikes_kalman         : int        # number of spikes unit 1
num_spikes_mog            : int        # number of spikes unit 2
hit_frac                  : float      # percent hits
mean_hits = NULL          : mediumblob # average waveform of all hits
mean_missed_kalman = NULL : mediumblob # average waveform of misses by first algo
mean_missed_mog = NULL    : mediumblob # average waveform of misses by second algo
ex_hits = NULL            : longblob   # examples of hits
ex_missed_kalman = NULL   : longblob   # examples
ex_missed_mog = NULL      : longblob   # examples
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
            unitsMoG = fetch(sort.TetrodesMoGLink(rmfield(key, 'sort_method_num')));
            unitsMoKsm = fetch(sort.KalmanLink(key));

            % Kalman clustering results
            model = uncompress(MoKsmInterface(fetch1(sort.KalmanFinalize(key), 'final_model')));
            
            % MoG clustering results
            sortFile = [fetch1(sort.Sets(setfield(key, 'sort_method_num', 2)), 'sort_set_path') sprintf('/clusteringTT%d.mat', key.electrode_num)]; %#ok
            clustering = getfield(load(getLocalPath(sortFile)), 'clustering'); %#ok
            
            % test all combinations
            for unitMoKsm = unitsMoKsm'
                for unitMoG = unitsMoG'

                    tuple = key;
                    tuple.cluster_number = unitMoKsm.cluster_number;
                    tuple.compare_to_number = unitMoG.cluster_number;
                    
                    % spike indices for the two clusters
                    si = getSpikesByClusIds(model, tuple.cluster_number);
                    % MoG wasn't used on the entire dataset but subset
                    si = si(si >= clustering.idxRangeBegin & si <= clustering.idxRangeEnd);
                    sj = find(clustering.cluBySpike == tuple.compare_to_number);

                    [hits, hiti, hitj] = intersect(si, sj);
                    missMog = si(setdiff(1 : numel(si), hiti));
                    missKal = sj(setdiff(1 : numel(sj), hitj));
                    
                    tuple.num_spikes_kalman = numel(si);
                    tuple.num_spikes_mog = numel(sj);
                    tuple.hits = numel(hits);
                    tuple.missed_kalman = numel(missKal);
                    tuple.missed_mog = numel(missMog);
                    
                    % is the comparison a match? store waveform examples
                    tuple.match = tuple.hits / min(tuple.num_spikes_kalman, tuple.num_spikes_mog);
                    if tuple.match > 0.8
                        N = 10000;
                        w = cat(1, model.Waveforms.data{:});
                        tuple.mean_hits = mean(w(:, hits), 2);
                        tuple.mean_missed_kalman = mean(w(:, missKal), 2);
                        tuple.mean_missed_mog = mean(w(:, missMog), 2);
                        r = randperm(numel(hits));
                        tuple.ex_hits = w(:, hits(r(1 : min(N, end))));
                        r = randperm(numel(missKal));
                        tuple.ex_missed_kalman = w(:, missKal(r(1 : min(N, end))));
                        r = randperm(numel(missMog));
                        tuple.ex_missed_mog = w(:, missMog(r(1 : min(N, end))));
                    end
                    self.insert(tuple);
                end
            end
        end
    end
end
