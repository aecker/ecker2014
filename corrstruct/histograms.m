function histograms
% Summary histograms for Fano factors and noise correlations.
% AE 2013-05-22

% key for analysis parameters
keys.project_name = 'NoiseCorrAnesthesia';
keys.sort_method_num = 5;
keys.spike_count_start = 30;
keys.spike_count_end = 530;
keys.max_instability = 0.1;
keys.min_trials = 20;
keys.min_cells = 10;
keys.max_contam = 1;
keys = genKey(keys, 'state', flipud(unique(fetchn(nc.Anesthesia, 'state'))));

fig = Figure(2, 'size', [100 100]); clf

% Fano factors
M = 2;
N = 2;
K = 1;
subplot(M, N, K); K = K + 1;
hold on
b = 0.15;
bins = 0.1 : b : 4;
F = cell(1, numel(keys));
fr = cell(1, numel(keys));
for iKey = 1 : numel(keys)
    key = keys(iKey);
    [F{iKey}, fr{iKey}] = fetchn(nc.AnalysisUnits * nc.UnitStats & key, 'mean_fano', 'mean_rate');
    h = hist(F{iKey}, bins);
    h = h / sum(h);
    sgn = -sign(iKey - 1.5);
    hdl = bar(bins, sgn * h, 1);
    set(hdl, 'FaceColor', colors(key.state), 'LineStyle', 'none')
    plot(nanmean(F{iKey}), 0.1 * sgn, '.k')
end
axisTight()
set(gca, 'xlim', [bins(1) - b/2, bins(end) + b/2], 'ylim', max(abs(ylim)) * [-1 1])
plot([1 1], ylim, '--k')
xlabel('Fano factor')
ylabel('Fraction of cells')
axis square

subplot(M, N, K); K = K + 1;
hold on
bins = -1 : 6;
for iKey = 1 : numel(keys)
    ndx = fr{iKey} > 0;
    [m, se, binc] = makeBinned(log2(fr{iKey}(ndx)), F{iKey}(ndx), bins, @mean, @(x) std(x) / sqrt(numel(x)), 'include');
    errorbar(binc, m, se, '.-', 'color', colors(keys(iKey).state))
end
axisTight()
set(gca, 'xlim', bins([1 end]), 'xtick', 0 : 2 : 6, 'xticklabel', 2 .^ (0 : 2 : 6))
xlabel('Mean firing rate (spikes/s)')
ylabel('Average Fano factor')
axis square

fprintf('Fano factors\n')
for i = 1 : numel(keys)
    fprintf('  %s: mean: %.2f (%d cells)\n', keys(i).state, nanmean(F{i}), numel(F{i}))
end
p = ranksum(F{:});
fprintf('  Rank sum test for difference: p = %.2g\n\n', p)


% noise correlations
subplot(M, N, K); K = K + 1;
hold on
b = 0.025;
bins = -0.25 : b : 0.4;
r = cell(1, numel(keys));
for iKey = 1 : numel(keys)
    key = keys(iKey);
    [r{iKey}, fr{iKey}] = fetchn(nc.AnalysisStims * nc.CleanPairs * nc.NoiseCorrelations & key, 'r_noise_avg', 'geom_mean_rate');
    h = hist(r{iKey}, bins);
    h = h / sum(h);
    sgn = -sign(iKey - 1.5);
    hdl = bar(bins, sgn * h, 1);
    set(hdl, 'FaceColor', colors(key.state), 'LineStyle', 'none')
    plot(nanmean(r{iKey}), 0.1 * sgn, '.k')
end
axisTight()
set(gca, 'xlim', [bins(1) - b/2, bins(end) + b/2], 'ylim', max(abs(ylim)) * [-1 1], 'box', 'off')
plot([0 0], ylim, '--k')
xlabel('Noise correlation')
ylabel('Fraction of pairs')
axis square

fprintf('Noise correlations\n')
for i = 1 : numel(keys)
    fprintf('  %s: mean: %.3f (%d pairs)\n', keys(i).state, nanmean(r{i}), numel(r{i}))
end
fprintf('  Rank sum test for difference: p = %.2g\n\n', ranksum(r{:}))


subplot(M, N, K); K = K + 1;
hold on
bins = -1 : 6;
for iKey = 1 : numel(keys)
    [m, se, binc] = makeBinned(log2(fr{iKey}), r{iKey}, bins, @mean, @(x) std(x) / sqrt(numel(x)), 'include');
    errorbar(binc, m, se, '.-', 'color', colors(keys(iKey).state))
end
axisTight()
set(gca, 'xlim', bins([1 end]), 'xtick', 0 : 2 : 6, 'xticklabel', 2 .^ (0 : 2 : 6))
xlabel('Geometric mean rate (spikes/s)')
ylabel('Average noise correlation')
axis square

fig.cleanup();
fig.save(strrep(mfilename('fullpath'), 'code', 'figures'));
