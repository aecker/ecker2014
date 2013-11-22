function fig7_lfp
% Fig. 7: Low-frequency LFP as a predictor of network state
%
% AE 2013-09-04

% key for analysis parameters
keys.project_name = 'NoiseCorrAnesthesia';
keys.sort_method_num = 5;
keys.min_freq = 0.5;
keys.max_freq = 10;
keys.spike_count_start = 30;
keys.control = 0;
keys.bin_size = 100;
keys.max_instability = 0.1;
keys.min_trials = 20;
keys.min_cells = 10;
keys.max_contam = 1;
keys.transform_num = 5;
keys.max_latent_dim = 1;
keys.latent_dim = 1;
keys.kfold_cv = 1;
keys.zscore = false;
keys = genKey(keys, 'state', flipud(unique(fetchn(nc.Anesthesia, 'state'))));

fig = Figure(7, 'size', [95 95]);
M = 2; N = 2;

for i = 1 : numel(keys)
    key = keys(i);
    
    % Cross-correlation between lowpass LFP and GPFA network state
    xc = fetchn(nc.AnalysisStims * nc.LfpGpfaCorr * nc.GpfaParams & key, 'xcorr_trial');
    xc = [xc{:}];
    subplot(M, N, i);
    hold on
    T = (size(xc, 1) - 1) / 2;
    t = (-T : T) * key.bin_size;
    plot(t, xc, 'color', 0.5 * ones(1, 3));
    plot(t, mean(xc, 2), 'color', colors(key.state), 'linewidth', 2)
    xlabel('Offset (ms)')
    if i == 1
        ylabel('Cross-correlation')
    end
    axis([[-1 1] * min(1000, T * key.bin_size), -0.6001, 0.4], 'square')
    
    % LFP weights in GLM
    rel = nc.AnalysisStims * nc.LfpGlmSet * nc.LfpGlm & key;
    w = fetchn(nc.UnitStats, rel, 'AVG(lfp_weight) -> w');
    subplot(M, N, N + i);
    p = prctile(w, [10 90]);
    p = ((i == 1) + 2) * [-1 1] * max(abs(p));
    bins = linspace(p(1), p(2), 24);
    h = hist(w, bins);
    h = h / sum(h);
    bar(bins, h, 1, 'FaceColor', colors(key.state), 'LineStyle', 'none');
    hold on
    xlabel('Weight')
    if i == 1
        ylabel('Fraction of cells')
    end
    axis tight square
    ylim([0 0.22])
    plot([0 0], ylim, '--k')
    set(gca, 'xticklabel', get(gca, 'xtick'))  % remove x10^-y notation
end

fig.cleanup()
file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save(file)
