function histograms
% Summary histograms for Fano factors and noise correlations.
% AE 2013-05-22

% key for analysis parameters
keys = struct('sort_method_num', 5, ...
              'max_instability', 0.1, ...
              'max_contam', 0.1, ...
              'spike_count_end', {530 530}, ...
              'state', {'awake', 'anesthetized'});

fig = Figure(1, 'size', [100, 50]); clf

% Fano factors
subplot(1, 2, 1)
hold on
b = 0.15;
bins = 0.1 : b : 4;
for iKey = 1 : numel(keys)
    key = keys(iKey);
    restr = sprintf('tac_instability < %f AND (fp + fn) < %f', key.max_instability, key.max_contam);
    F = fetchn(nc.Anesthesia * nc.UnitStats * ephys.SingleUnit & key & restr, 'mean_fano');
    h = hist(F, bins);
    h = h / sum(h);
    sgn = -sign(iKey - 1.5);
    hdl = bar(bins, sgn * h, 1);
    set(hdl, 'FaceColor', colors(key.state), 'LineStyle', 'none')
    plot(nanmean(F), 0.1 * sgn, '.k')
end
axisTight()
set(gca, 'xlim', [bins(1) - b/2, bins(end) + b/2], 'ylim', max(abs(ylim)) * [-1 1], 'box', 'off')
plot([1 1], ylim, '--k')
xlabel('Fano factor')
ylabel('Fraction of cells')

% noise correlations
subplot(1, 2, 2)
hold on
b = 0.025;
bins = -0.25 : b : 0.4;
for iKey = 1 : numel(keys)
    key = keys(iKey);
    r = fetchn(nc.Anesthesia * nc.CleanPairs * nc.NoiseCorrelations & key, 'r_noise_avg');
    h = hist(r, bins);
    h = h / sum(h);
    sgn = -sign(iKey - 1.5);
    hdl = bar(bins, sgn * h, 1);
    set(hdl, 'FaceColor', colors(key.state), 'LineStyle', 'none')
    plot(nanmean(r), 0.1 * sgn, '.k')
end
axisTight()
set(gca, 'xlim', [bins(1) - b/2, bins(end) + b/2], 'ylim', max(abs(ylim)) * [-1 1], 'box', 'off')
plot([0 0], ylim, '--k')
xlabel('Noise correlation')
ylabel('Fraction of pairs')

fig.cleanup();
fig.save(strrep(mfilename('fullpath'), 'code', 'figures'));
