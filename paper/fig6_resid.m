function fig6_resid
% Fig. 6: Residual noise correlations after accounting for network state.
%
% AE 2013-08-30

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
keys.kfold_cv = 2;
keys.zscore = false;
keys.control = 0;
keys.int_bins = 5;
keys = genKey(keys, 'state', flipud(unique(fetchn(nc.Anesthesia, 'state'))));

fig = Figure(6, 'size', [100 100]);
M = 2; N = 2;
hdl1 = zeros(2);
hdl2 = zeros(2);
linestyles = {'.-', '.--'};
for i = 1 : numel(keys)
    for p = 0 : 1
        
        key = keys(i);
        key.latent_dim = p;
        rel = nc.AnalysisStims * nc.GpfaParams * nc.GpfaModelSet * nc.GpfaResidCorr ...
            * nc.NoiseCorrelations * nc.NoiseCorrelationConditions;
        [resid, gmr, rs, d, st] = fetchn(rel & key, ...
            'resid_corr_test', 'geom_mean_rate_cond', 'r_signal', 'distance', 'stim_start_time');
        
        K = 1;
        color = colors(key.state);
        linestyle = linestyles{p + 1};
        
        % Firing rate
        bins = -1 : 6;
        doPlots(log2(gmr), bins, 'Geometric mean firing rate');
        set(gca, 'xtick', bins(2 : end - 1), 'xticklabel', 2 .^ bins(2 : end - 1), 'xlim', bins([1 end]))
        
        % Signal correlation
        bins = -1 : 0.2 : 1;
        hdl1(p + 1, i) = doPlots(rs, bins, 'Signal correlation');
        set(gca, 'xlim', bins([1 end]))
        
        % Distance
        bins = 0 : 0.5 : 4;
        hdl2(p + 1, i) = doPlots(d, bins, 'Distance');
        set(gca, 'xlim', bins([1 end]))
    end
end

legend(hdl1(1, :), keys.state)
legend(hdl2(:, 1), {'p = 0', 'p = 1'})

file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save(file)

    function hdl = doPlots(x, bins, xlbl)
        subplot(M, N, K); K = K + 1;
        hold on
        [m, se] = binnedMeanAndErrorbars(x, resid, st, bins);
        binc = makeBinned([], [], bins);
        hdl = errorbar(binc, m, se, linestyle, 'color', color, 'markersize', 5);
        xlabel(xlbl)
        ylabel('Avg. residual correlation')
        axisTight
        axis square
    end

end


function [m, se] = binnedMeanAndErrorbars(x, y, st, bins)
% Compute binned means and error bars.
%   Since the simultaneously recorded pairs aren't independent we can't
%   just use SEM = SD / sqrt(n), since this would underestimate the true
%   standard error. Instead we compute the binned means for each site and
%   then take the SEM over sites. This is not the theoretically optimal
%   solution since the binned means have different errors (they don't
%   contain the same number of data point) and we don't do any error
%   propagation. However, it's a conservative estimate of the SEM since the
%   more reliable data points are given less weight than they should and we
%   therefore overestimate the overall error.

% compute overall binned means (it's the more reliable estimate than first
% averaging sites)
m = makeBinned(x, y, bins, @mean, 'include');

% compute binned means for each site used for error bars
ust = unique(st);
n = numel(ust);
ym = cell(1, n);
for i = 1 : n
    ndx = st == ust(i);
    ym{i} = makeBinned(x(ndx), y(ndx), bins, @mean, 'include');
end
ym = [ym{:}];
se = nanstd(ym) ./ sqrt(sum(~isnan(ym), 2));
end


function sigma = nanstd(x)
% Standard deviation ignoring NaNs (to avoid usage of stats toolbox).

n = size(x, 1);
sigma = zeros(n, 1);
for i = 1 : n
    sigma(i) = std(x(i, ~isnan(x(i, :))));
end
end
