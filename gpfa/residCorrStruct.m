function residCorrStruct(pmax, transformNum, zscore, byTrial, coeff)
% Structure of residual correlations.
%   residCorrStruct(pmax, transformNum, zscore, byTrial, coeff)
%
%   Plot correlation structure for residual correlations: dependence on
%   firing rates, signal correlations, difference in preferred
%   orientations, and distance.
%
% AE 2013-01-22

figure(1000 * transformNum + 100 * zscore + 10 * byTrial + coeff), clf
M = 3;
N = 2;
covText = {'covariance', 'correlation'};
colors = lines(pmax + 1);
hdl1 = zeros(pmax + 1, 2);
hdl2 = hdl1;
for p = 0 : pmax

    restrictions = {'subject_id in (9, 11) AND sort_method_num = 5 AND kfold_cv = 2', ...
        struct('latent_dim', p, 'transform_num', transformNum, 'zscore', zscore, 'by_trial', byTrial)};
    
    offdiag = @(C) C(~tril(ones(size(C))));
    corr = @(C) C ./ sqrt(diag(C) * diag(C)');
    
    keys = fetch(nc.GpfaParams * nc.GpfaCovExpl & restrictions & 'cv_run = 1')';
    props = cell(numel(keys), 5);
    resid = cell(numel(keys), 2);
    for iKey = 1 : numel(keys);
        key = keys(iKey);
        
        % fetch properties of pairs
        [props{iKey, :}] = fetchOffdiag(nc.GpfaModelSet & key, nc.NoiseCorrelations * nc.NoiseCorrelationConditions, ...
            'geom_mean_rate_cond', 'min_rate_cond', 'r_signal', 'diff_pref_ori', 'distance');
        
        % get residual correlations
        [resid{iKey, :}] = fetch1(nc.GpfaCovExpl & key, 'cov_resid_train', 'cov_resid_test');
    end
    
    % extract off-diagonals (and normalize)
    if coeff
        fun = @(C) offdiag(corr(C));
    else
        fun = offdiag;
    end
    resid = cellfun(fun, resid, 'uni', false);
    
    % plots
    K = 1;
    color = colors(p + 1, :);
    
    bins = [-1 : 6, 8];
    gmr = cellfun(@log2, props(:, 1), 'uni', false);
    doPlots(gmr, bins, 'Geometric mean firing rate');
    set(gca, 'xlim', bins([1 end]), 'xtick', bins, 'xticklabel', 2 .^ bins)
    
    mr = cellfun(@log2, props(:, 2), 'uni', false);
    doPlots(mr, -2 : 7, 'Minimum firing rate');
    set(gca, 'xtick', -1 : 6, 'xticklabel', 2 .^ (-1 : 6))
    
    doPlots(props(:, 3), -1 : 0.2 : 1, 'Signal correlation');
    hdl1(p + 1, :) = doPlots(props(:, 4), linspace(0, pi / 2, 10), 'Difference in pref ori');
    hdl2(p + 1, :) = doPlots(props(:, 5), 0 : 0.5 : 4, 'Distance');
end

legend(hdl1(:, 2), arrayfun(@(x) sprintf('p = %d', x), 0 : pmax, 'uni', false))
legend(hdl2(1, :), {'Test set', 'Training set'})

    function hdl = doPlots(x, bins, xlbl)
        subplot(M, N, K); K = K + 1;
        hold on
        [mTrain, seTrain] = binnedMeanAndErrorbars(x, resid(:, 1), bins);
        [mTest, seTest] = binnedMeanAndErrorbars(x, resid(:, 2), bins);
        binc = makeBinned([], [], bins);
        hdl = [errorbar(binc, mTrain, seTrain, '--', 'color', color), ...
               errorbar(binc, mTest, seTest, '-', 'color', color)];
        xlabel(xlbl)
        ylabel(['Average residual ' covText{coeff + 1}])
        set(gca, 'box', 'off')
        axisTight
    end

end


function [m, se] = binnedMeanAndErrorbars(x, y, bins)
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
m = makeBinned(cat(1, x{:}), cat(1, y{:}), bins, @mean);

% compute binned means for each site used for error bars
ym = cellfun(@(x, y) makeBinned(x, y, bins, @mean), x, y, 'uni', false);
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
