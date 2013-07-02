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
index_offset              : int        # spike index offset
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
            
            % Determine index offset. Indices are sometimes off, presumably
            % because of some inconsistentcy when loading the entire file
            % or loading spikes by index. This may be because of zero-based
            % indexing in C/C++, but may also be file-type specific. So we
            % just determine the offset here
            if ~isempty(clustering.spikeTimes)
                first = min(clustering.noiseTimes(1), min(cellfun(@(x) x(1), clustering.spikeTimes)));
            else
                first = clustering.noiseTimes(1);
            end
            [~, ndx] = min(abs(first - model.t));
            offset = clustering.idxRangeBegin - ndx;
            key.index_offset = offset;
            
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

                    [hits, hiti, hitj] = intersect(si + offset, sj);
                    missMog = si(setdiff(1 : numel(si), hiti));
                    missKal = sj(setdiff(1 : numel(sj), hitj));
                    
                    tuple.num_spikes_kalman = numel(si);
                    tuple.num_spikes_mog = numel(sj);
                    tuple.hits = numel(hits);
                    tuple.missed_kalman = numel(missKal);
                    tuple.missed_mog = numel(missMog);
                    
                    % is the comparison a match? store waveform examples
                    tuple.hit_frac = tuple.hits / min(tuple.num_spikes_kalman, tuple.num_spikes_mog);
                    if tuple.hit_frac > 0.8
                        w = cat(1, model.Waveforms.data{:});
                        tuple.mean_hits = mean(w(:, hits), 2);
                        tuple.mean_missed_kalman = mean(w(:, missKal), 2);
                        tuple.mean_missed_mog = mean(w(:, missMog), 2);
                    end
                    self.insert(tuple);
                end
            end
        end
    end
end
