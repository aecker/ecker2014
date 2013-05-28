function residCorrStruct(varargin)
% Structure of residual correlations.
%   residCorrStruct()
%
%   Plot correlation structure for residual correlations: dependence on
%   firing rates, signal correlations, difference in preferred
%   orientations, and distance.
%
% AE 2013-05-21

% key for analysis parameters/subjects etc.
key.transform_num = 5;
key.zscore = false;
key.by_trial = false;
key.sort_method_num = 5;
key.bin_size = 100;
key.max_latent_dim = 1;
key.min_stability = 0.1;
key.kfold_cv = 2;
key.control = 0;
key = genKey(key, varargin{:});
assert(isscalar(key), 'Key must be unique!')

states = {'awake', 'anesthetized'};

fig = Figure(1 + key.by_trial, 'size', [90 120]); clf
M = 3;
N = 2;
hdl1 = zeros(2);
hdl2 = zeros(2);
linestyles = {'-', '--'};
for iState = 1 : numel(states)
    for p = 0 : 1
        
        curKey = key;
        curKey.state = states{iState};
        curKey.latent_dim = p;
%         if iState == 1
%             curKey.subject_id = 8;
%         end
        
        rel = nc.Anesthesia * nc.GpfaPairs * nc.GpfaParams * nc.GpfaModelSet ...
            * nc.GpfaCovExpl * nc.NoiseCorrelations * nc.NoiseCorrelationConditions;
        
        [gmr, mr, rs, dp, d, st] = fetchn(rel & curKey, ...
            'geom_mean_rate_cond', 'min_rate_cond', 'r_signal', 'diff_pref_ori', 'distance', 'stim_start_time', ...
            'ORDER BY stim_start_time, condition_num, index_j, index_i');
        
        resid = fetchn(nc.Anesthesia * nc.GpfaParams * nc.GpfaCovExpl & curKey, ...
            'corr_resid_test', 'ORDER BY stim_start_time, condition_num');
        
        % extract off-diagonals (and normalize)
        offdiag = @(C) C(~tril(ones(size(C))));
        resid = cellfun(offdiag, resid, 'uni', false);
        resid = cat(1, resid{:});
        
        % plots
        K = 1;
        color = colors(states{iState});
        linestyle = linestyles{p + 1};
        
        bins = -1 : 6;
        doPlots(log2(gmr), -1 : 6, 'Geometric mean firing rate');
        set(gca, 'xtick', bins(2 : end - 1), 'xticklabel', 2 .^ bins(2 : end - 1))
        
        doPlots(log2(mr), bins, 'Minimum firing rate');
        set(gca, 'xtick', bins(2 : end - 1), 'xticklabel', 2 .^ bins(2 : end - 1))
        
        doPlots(rs, -1 : 0.2 : 1, 'Signal correlation');
        hdl1(p + 1, iState) = doPlots(dp, linspace(0, pi / 2, 10), 'Difference in pref ori');
        hdl2(p + 1, iState) = doPlots(d, 0 : 0.5 : 4, 'Distance');
    end
end

legend(hdl1(1, :), states)
legend(hdl2(:, 1), {'p = 0', 'p = 1'})

byTrial = {'_bins', '_trials'};
file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save([file byTrial{key.by_trial + 1}])

    function hdl = doPlots(x, bins, xlbl)
        subplot(M, N, K); K = K + 1;
        hold on
        [m, se] = binnedMeanAndErrorbars(x, resid, st, bins);
        binc = makeBinned([], [], bins);
        hdl = errorbar(binc, m, se, linestyle, 'color', color);
        xlabel(xlbl)
        ylabel('Average residual correlation')
        set(gca, 'box', 'off')
        axisTight
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
