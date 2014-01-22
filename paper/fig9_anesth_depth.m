function fig9_anesth_depth
% Fig. 9: Depth of anesthesia
%   We estimate depth of anesthesia by taking the ratio of low-frequency
%   LFP power to gamma power and correlate it with the overall level of
%   correlations as measured by the variance of the network state variable.
%
% AE 2013-11-22

% key for analysis parameters
key.project_name = 'NoiseCorrAnesthesia';
key.sort_method_num = 5;
key.low_min = 0.5;
key.low_max = 2;
key.high_min = 30;
key.high_max = 70;
key.spike_count_start = 30;
key.control = 0;
key.bin_size = 100;
key.max_instability = 0.1;
key.min_trials = 20;
key.min_cells = 10;
key.max_contam = 1;
key.transform_num = 5;
key.max_latent_dim = 1;
key.latent_dim = 1;
key.kfold_cv = 1;
key.zscore = false;
key.all_tt = false;
key.num_blocks = 100;
key.state = 'anesthetized';

fig = Figure(8, 'size', [200 60]);

% Two example sessions
exKeys = struct('stim_start_time', {3412243355000, 3435663381000});
for i = 1 : 2
    [S, f, VarX, start, stop] = fetch1(acq.Stimulation * nc.NetworkStateVar * nc.LfpSpectrogram & key & exKeys(i), ...
        'spectrogram', 'frequencies', 'var_x', 'stim_start_time', 'stim_stop_time');
    t = linspace(0, double((stop - start) / 1000 / 60), 2 * key.num_blocks - 1);
    subplot(3, 3, i)
    ndx = f > 3 & f < 60;
    imagesc(t, f(ndx), db(abs(S(ndx, :))))
    axis xy
    colorbar
    if i == 1
        caxis([-65 -25])
        ylabel('Frequency (Hz)')
    else
        caxis([-62 -15])
    end
    
    subplot(3, 3, 3 + i)
    ndx = f > 0.5 & f < 3;
    imagesc(t, f(ndx), db(abs(S(ndx, :))))
    axis xy
    colorbar
    ylim([0.5, 3 + eps])
    if i == 1
        caxis([-50 -10])
        ylabel('Frequency (Hz)')
    else
        caxis([-40 0])
    end
    
    subplot(3, 3, 6 + i)
    low = f > key.low_min & f < key.low_max;
    high = f > key.high_min & f < key.high_max;
    ratio = mean(abs(S(low, :)), 1) ./ mean(abs(S(high, :)), 1);
    hold on
    plot(t, VarX / mean(VarX), '-r')
    plot(t, ratio / mean(ratio), '-k')
    axis tight
    ylim([0.3, 2.7])
    colorbar
    xlabel('Time (minutes)')
    if i == 1
        legend({'Correlation', 'Power ratio'})
        ylabel('Magnitude')
    end
end

% Summary plot
subplot(3, 3, [3 6 9])
key.num_blocks = 20;
rel = nc.LfpPowerRatioGpfa * nc.LfpPowerRatioGpfaParams * nc.GpfaParams;
[VarX, ratio] = fetchn(rel & key, 'rel_var_x', 'rel_power_ratio');
plot(ratio, VarX, '.k', 'markersize', 4)
xlabel('Relative LFP power ratio')
ylabel('Relative Var of network state')
ax = [0.25, 4, 0.25 1.75];
axis(ax, 'square')
set(gca, 'xscale', 'log', 'xtick', 2 .^ (-2 : 2), 'ytick', ax(3) : 0.25 : ax(4))
fprintf('%d outlier(s) cropped\n', sum(ratio < ax(1) | ratio > ax(2) | VarX < ax(3) | VarX > ax(4)))

% Statistics
[rho, p] = corr(ratio, VarX, 'type', 'spearman');
fprintf('Correlation coefficient: %.2g (p = %.2g)\n', rho, p)

% Per monkey statistics
fprintf('Individual monkeys\n')
for k = fetch(nc.Anesthesia & key)'
    [VarX, ratio] = fetchn(rel & key & k, 'rel_var_x', 'rel_power_ratio');
    [rho, p] = corr(ratio, VarX, 'type', 'spearman');
    fprintf('  r = %.2g (p = %.2g)\n', rho, p)
end

% Per session statistics
%   Here we use more blocks. Although this reduces the magnitude of the
%   correlations since within each block it's noisier, it increases the
%   power for detecting significant correlations within a single session.
key.num_blocks = 100;
keys = fetch(nc.LfpPowerRatioGpfaSet * nc.LfpPowerRatioGpfaParams * nc.GpfaParams & key);
nk = numel(keys);
rho = zeros(1, nk);
p = zeros(1, nk);
for i = 1 : nk
    [VarX, ratio] = fetchn(rel & keys(i), 'rel_var_x', 'rel_power_ratio');
    [rho(i), p(i)] = corr(ratio, VarX, 'type', 'spearman');
end
fprintf('Significant positive correlation (p < 0.05) in %d/%d sessions\n', sum(p < 0.05 & rho > 0), nk)

fig.cleanup()
file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save(file)
