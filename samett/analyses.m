%% Noise correlations within tetrodes
% AE 2013-07-08


%% Awake monkeys: grouped by tetrode
% Here we group the data by tetrode and compute average signal and noise
% correlations for each tetrode.

corrByTetrode(true, 'by_trial', false)
corrByTetrode(true, 'by_trial', true)


%% Distribution of number of neurons
subjectIds = [9 11 28];
for i = 1 : numel(subjectIds)
    key = struct('subject_id', subjectIds(i));
    [n, tt, st] = fetchn(ae.Electrodes * nc.Gratings & key, ...
        ephys.Spikes * acq.EphysStimulationLink & key & 'sort_method_num = 5', ...
        'count(1)->n', 'electrode_num', 'stim_start_time');
    n = makeBinned2(double(st), tt, double(n), [unique(double(st)); inf], [unique(tt); inf], @(x) x);
    subplot(1, 3, i)
    imagesc(n)
    xlabel('Tetrode #')
    caxis([0 5])
end

