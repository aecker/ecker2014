function figS3_xcorr
% Fig. S3: Timescale of correlations by integrating cross-correlogram
%   Here we integrate the cross-correlogram to compute the timescale of
%   correlation as suggested by Bair et al. 2001 (J Neurosci) to compare
%   it to the data from Smith & Kohn 2008
%
% AE 2013-11-28

% key for analysis parameters
key.project_name = 'NoiseCorrAnesthesia';
key.sort_method_num = 5;
key.spike_count_start = 30;
key.spike_count_end = 2030;
key.max_instability = 0.1;
key.min_trials = 20;
key.min_cells = 10;
key.max_contam = 0.1;
key.state = 'anesthetized';

fig = Figure(101, 'size', [120 60]);

rel = nc.CrossCorr * nc.Anesthesia * nc.CleanPairs * nc.NoiseCorrelations;
ccg = fetchn(rel & key & 'distance > 0', 'ccg');
ccg = mean([ccg{:}], 2);
ccg = (ccg + flipud(ccg)) / 2;  % make symmetric
T = size(ccg, 1);
t = (1 : T) - (T + 1) / 2;

subplot(1, 2, 1)
plot(t, ccg, 'k')
set(gca, 'xlim', 500 * [-1 1], 'xtick', -500 : 250 : 500, 'ylim', [0 1] * 1e-3)
xlabel('Time lag (ms)')
ylabel('Cross-correlation (coincidences/spike)')

[c, cb] = fetchn(nc.CrossCorr * nc.Anesthesia * nc.CleanPairs & key, 'r_ccg', 'r_ccg_bair');
c = [c{:}];
cb = [cb{:}];
ndx = ~any(isnan(cb) | imag(cb) | isnan(c), 1);
C = mean(c(:, ndx), 2);
Cb = mean(cb(:, ndx), 2);
t = 1 : numel(C);

subplot(1, 2, 2)
plot(t, Cb, 'r', t, C, 'k')
set(gca, 'xscale', 'log', 'xlim', [1 2000], 'ylim', [0 0.1], 'xtick', ...
    [1 10 100 1000], 'xticklabel', [1 10 100 1000])
xlabel('Integration time (ms)')
ylabel('Cumulative correlation')
legend({'Bair''s method', 'Normalized by total variance'})

fig.cleanup()

file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save(file)
