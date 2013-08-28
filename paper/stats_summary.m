function summary()
% Summary statistics for dataset
% AE 2013-08-26

key.project_name = 'NoiseCorrAnesthesia';
key.sort_method_num = 5;
key.spike_count_start = 30;
key.spike_count_end = 530;
key.max_instability = 0.1;
key.min_trials = 20;
key.min_cells = 10;
key.max_contam = 1;
key = genKey(key, 'state', flipud(unique(fetchn(nc.Anesthesia, 'state'))));

for k = key'
    
    % general dataset
    n = double(fetchn(nc.AnalysisStims, nc.AnalysisUnits & k, 'count(1) -> n'));
    fprintf('\nBrain state: %s\n', k.state)
    fprintf('  Single units: %d\n', count(nc.AnalysisUnits & k))
    fprintf('  nc.AnalysisStims: %d (%d drifting, %d static)\n', ...
        count(nc.AnalysisStims & k), ...
        count(nc.AnalysisStims * nc.Gratings & k & 'speed > 0'), ...
        count(nc.AnalysisStims * nc.Gratings & k & 'speed = 0'))
    fprintf('  Single units per session\n    range: %d - %d\n    median: %g\n', ...
        min(n), max(n), median(n))
    
    % contamination
    c = fetchn(nc.AnalysisUnits * ephys.SingleUnit & k, 'fp + fn -> c');
    fprintf('  Contamination\n    <10%%: %.1f%%\n    <20%%: %.1f%%\n', 100 * mean(c < 0.1), 100 * mean(c < 0.2))
    
    % orientation tuning
    p = fetchn(nc.AnalysisUnits, nc.AnalysisUnits * nc.OriTuning & k, 'min(ori_sel_p) -> p');
    tuned = p < 0.01;
    fprintf('  Orientation tuning: %.1f%% (%d/%d)\n', 100 * mean(tuned), sum(tuned), numel(tuned))
    fprintf('\n')    
end
