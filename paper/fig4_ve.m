function fig4_ve
% Fig. 4: Variance explained by one-factor GPFA model.
%   Here I compute percent variance explained on the test set for the one-
%   factor GPFA model for each cell as a function of both firing rates and
%   brain state.
%
% AE 2013-08-28

% key for analysis parameters
keys.project_name = 'NoiseCorrAnesthesia';
keys.sort_method_num = 5;
keys.spike_count_start = 30;
keys.max_instability = 0.1;
keys.min_trials = 20;
keys.min_cells = 10;
keys.max_contam = 1;
keys.bin_size = 100;
keys.transform_num = 5;
keys.max_latent_dim = 1;
keys.latent_dim = 1;
keys.kfold_cv = 2;
keys.zscore = false;
keys.control = 0;
keys.int_bins = 5;
keys = genKey(keys, 'state', flipud(unique(fetchn(nc.Anesthesia, 'state'))));

fig = Figure(4, 'size', [100 100]);
M = 2; N = 2;
n = numel(keys);
frbins = -1 : 7;
scax = [-1 8 -0.5 1];
bax = [frbins([1 end]) 0 0.4];
intbins = [1 2 5 10 20];
ints = pro(nc.Integers, 'x -> int_bins') & sprintf('int_bins IN (0%s)', sprintf(', %d', intbins));

for i = 1 : n

    rel = nc.AnalysisStims * nc.GpfaParams * nc.GpfaModelSet * nc.GpfaVE * nc.UnitStatsConditions;
    [ve, fr] = fetchn(rel & keys(i), 've_test', 'mean_rate_cond');

    % scatter plots: variance explained vs. firing rate
    subplot(M, N, i)
    plot(log2(fr), ve, '.', 'color', colors(keys(i).state), 'markersize', 1)
    axis square
    axis(scax)
    set(gca, 'xticklabel', 2 .^ get(gca, 'xtick'))
    xlabel('Firing raten (spikes/s)')
    if i == 1
        ylabel('Variance explained')
    end
    
    % binned average VE as a function of firing rate
    subplot(M, N, 3)
    hold on
    [m, frbinsc] = makeBinned(log2(fr), ve, frbins, @mean, 'include');
    plot(frbinsc, m, '.-', 'color', colors(keys(i).state))
    axis square
    axis(bax)
    set(gca, 'xticklabel', 2 .^ get(gca, 'xtick'))
    xlabel('Firing rate (spikes/s)')
    ylabel('Average variance explained')

    % VE as a function of integration window
    subplot(M, N, 4)
    hold on
    rel = nc.AnalysisStims * nc.GpfaParams * nc.GpfaModelSet * nc.GpfaVE;
    [t, v] = fetchn(ints, rel & rmfield(keys(i), 'int_bins'), 'bin_size * int_bins -> t', 'AVG(ve_test) -> ve');
    plot(t, v, '.-', 'color', colors(keys(i).state))
    set(gca, 'xscale', 'log', 'xlim', intbins([1 end]) * keys(1).bin_size, ...
        'xtick', intbins * keys(1).bin_size, 'xminortick', 'off', 'ylim', [0 0.15001])
    xlabel('Integration window (ms)')
    axis square
end

subplot(M, N, 4)
set(legend(keys.state), 'location', 'east')

fig.cleanup()

file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save(file)
