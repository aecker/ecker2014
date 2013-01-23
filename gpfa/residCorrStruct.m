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

for p = 0 : pmax

    restrictions = {'subject_id in (9, 11) AND sort_method_num = 5 AND kfold_cv = 2', ...
        struct('latent_dim', p, 'transform_num', transformNum, 'zscore', zscore, 'by_trial', byTrial)};
    
    offdiag = @(C) C(~tril(ones(size(C))));
    corr = @(C) C ./ sqrt(diag(C) * diag(C)');
    
    keys = fetch(nc.GpfaCovExpl & restrictions & 'cv_run = 1')';
    props = cell(numel(keys), 5);
    resid = cell(numel(keys), 2);
    for iKey = 1 : numel(keys);
        key = keys(iKey);
        
        % fetch properties of pairs
        [props{iKey, :}] = fetchOffdiag(nc.GpfaModelSet & key, nc.NoiseCorrelations * nc.NoiseCorrelationConditions, ...
            'r_signal', 'geom_mean_rate_cond', 'min_rate_cond', 'diff_pref_ori', 'distance');
        
        % get residual correlations
        [resid{iKey, :}] = fetch1(nc.GpfaCovExpl & key, 'cov_resid_train', 'cov_resid_test');
    end
    
    % concatenate all sites/sessions
    rs = cat(1, props{:, 1});
    gmr = cat(1, props{:, 2});
    mr = cat(1, props{:, 3});
    dp = cat(1, props{:, 4});
    d = cat(1, props{:, 5});
    if coeff
        fun = @(C) offdiag(corr(C));
    else
        fun = offdiag;
    end
    resid2 = cellfun(fun, resid, 'uni', false);
    rtrain = cat(1, resid2{:, 1});
    rtest = cat(1, resid2{:, 2});
    
    % plots
    K = 1;
    color = colors(p + 1, :);
    
    bins = [-1 : 6, 8];
    doPlots(log2(gmr), bins, 'Geometric mean firing rate');
    set(gca, 'xlim', bins([1 end]), 'xtick', bins, 'xticklabel', 2 .^ bins)
    
    doPlots(log2(mr), -2 : 7, 'Minimum firing rate');
    set(gca, 'xtick', -1 : 6, 'xticklabel', 2 .^ (-1 : 6))
    
    doPlots(rs, -1 : 0.2 : 1, 'Signal correlation');
    doPlots(dp, linspace(0, pi / 2, 10), 'Difference in pref ori');
    doPlots(d, 0 : 0.5 : 4, 'Distance');
end


function doPlots(x, bins, xlbl)
    subplot(M, N, K); K = K + 1;
    hold on
    [m, se, binc] = makeBinned(x, rtrain, bins, @mean, @(x) std(x) / sqrt(numel(x)));
    errorbar(binc, m, se, '--', 'color', color)
    [m, se, binc] = makeBinned(x, rtest, bins, @mean, @(x) std(x) / sqrt(numel(x)));
    errorbar(binc, m, se, '-', 'color', color)
    xlabel(xlbl)
    ylabel(['Average residual ' covText{coeff + 1}])
    set(gca, 'box', 'off')
    axisTight
end

end
