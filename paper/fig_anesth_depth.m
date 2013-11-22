function fig_anesth_depth
% Fig.: Depth of anesthesia indicated by ratio of low-frequency LFP power
%   to gamma power.
%
% AE 2013-11-22

% key for analysis parameters
key.project_name = 'NoiseCorrAnesthesia';
key.sort_method_num = 5;
key.low_min = 0.5;
key.low_max = 2;
key.high_min = 30;
key.high_max = 70;
key.num_blocks = 20;
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
key.state = 'anesthetized';

fig = Figure(8, 'size', [60 60]);
rel = nc.LfpPowerRatioGpfa * nc.LfpPowerRatioGpfaParams * nc.GpfaParams;
[VarX, ratio] = fetchn(rel & key, 'delta_var_x', 'delta_power_ratio');
plot(ratio, VarX, '.k', 'markersize', 4)
xlabel('Relative LFP power ratio')
ylabel('Relative Var of network state')
ax = [-2, 2, -0.6 - eps, 0.6 + eps];
axis(ax)
axis square
fprintf('%d outlier(s) cropped\n', sum(ratio < ax(1) | ratio > ax(2) | VarX < ax(3) | VarX > ax(4)))

% Statistics
[rho, p] = corr(ratio, VarX, 'type', 'spearman');
fprintf('Correlation coefficient: %.2g (p = %.2g)\n', rho, p)

% Per monkey statistics
fprintf('Individual monkeys\n')
for k = fetch(nc.Anesthesia & key)'
    [VarX, ratio] = fetchn(rel & key & k, 'delta_var_x', 'delta_power_ratio');
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
    [VarX, ratio] = fetchn(rel & keys(i), 'delta_var_x', 'delta_power_ratio');
    [rho(i), p(i)] = corr(ratio, VarX, 'type', 'spearman');
end
fprintf('Significant positive correlation (p < 0.05) in %d/%d sessions\n', sum(p < 0.05 & rho > 0), nk)

fig.cleanup()
file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save(file)
