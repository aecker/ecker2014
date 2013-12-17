function suppl_fig_xcorr
% Suppl. Fig. 1: Timescale by integrating cross-correlogram
%   Here we integrate the cross-correlogram to compute the timescale of
%   correlation as suggested by Bair et al. 2001 (J Neurosci).
%
% AE 2013-11-28

% key for analysis parameters
key.project_name = 'NoiseCorrAnesthesia';
key.sort_method_num = 5;
key.spike_count_start = 30;
key.max_instability = 0.1;
key.min_trials = 20;
key.min_cells = 10;
key.max_contam = 0.1;
key.state = 'anesthetized';

fig = Figure(101, 'size', [60 60]);

[ccg, c, cb] = fetchn(nc.CrossCorr * nc.Anesthesia * nc.CleanPairs & key, 'ccg', 'r_ccg', 'r_ccg_bair');
ccg = mean([ccg{:}], 2);
c = [c{:}];
cb = [cb{:}];
ndx = ~any(isnan(cb) | imag(cb) | isnan(c), 1);
C = mean(c(:, ndx), 2);
Cb = mean(cb(:, ndx), 2);
T = size(ccg, 1);
[~, order] = sort(abs((1 : T) - (T + 1) / 2));
Ccg = cumsum(ccg(order));
t = 1 : numel(C);
plot(t, Cb, 'r', t, C, 'k', t, Ccg(1 : 2 : end) / Ccg(end) * C(end), ':k')
set(gca, 'xscale', 'log', 'xlim', [1 2000], 'ylim', [0 0.1], 'xtick', ...
    [1 10 100 1000], 'xticklabel', [1 10 100 1000])
xlabel('Integration time (ms)')
ylabel('Noise correlation')
legend({'Bair''s method', 'Normalized by total variance', 'Unnormalized and rescaled'})

fig.cleanup()

file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save(file)
