function factorLoadingTuningProps(transformNum, zscore, p)
% Correlate factor loadings with tuning properties.
%
% AE 2012-01-25

binSize = 100;
restrictions = {sprintf('subject_id in (9, 11) AND sort_method_num = 5 AND kfold_cv = 2 AND bin_size = %d', binSize), ...
                 struct('transform_num', transformNum, 'zscore', zscore)};
% cv_run = 1 AND  AND latent_dim = %d
groupKeys = fetch(ae.SpikesByTrialSet & (nc.GpfaModelSet & restrictions));
n = numel(groupKeys);
C = cell(n, 1);
base = cell(n, 1);
kappa = cell(n, 1);
ampl = cell(n, 1);
for iGroup = 1 : n
    key = groupKeys(iGroup);
    key.latent_dim = p;
    modelKeys = fetch(nc.GpfaModel & key & restrictions);
    nUnits = max(fetchn(nc.GpfaUnits & key & restrictions, 'unit_id'));
    nModels = numel(modelKeys);
    Ctmp = NaN(nUnits, p, nModels);
    for iModel = 1 : nModels
        [model, Y, train] = fetch1(nc.GpfaModelSet * nc.GpfaModel & modelKeys(iModel), ...
            'model', 'transformed_data', 'train_set');
        model = GPFA(model);
        model = model.normFactors(Y(:, :, train));  % normalize latent factors
        
        unitIds = sort(fetchn(nc.GpfaUnits & modelKeys(iModel), 'unit_id'));

        % order factors by variance explained
        Ci = model.C;
        [~, order] = sort(sqrt(sum(Ci .^ 2, 1)), 'descend');    % sort by norm
        Ci = Ci(:, order);
        Ctmp(unitIds, :, iModel) = bsxfun(@times, Ci, sign(median(Ci, 1)));         % sign flip
    end
    Ctmp = nanmean(Ctmp);
    C{iGroup} = Ctmp(~isnan(Ctmp(:, 1)), :);
    
    % get unit properties
    propsRel = nc.OriTuning & (nc.GpfaUnits & key & restrictions);
    [base{iGroup}, kappa{iGroup}, ampl{iGroup}] = ...
        fetchn(propsRel, 'ori_baseline', 'ori_kappa', 'ori_ampl');
end
C = cat(1, C{:});
base = cat(1, base{:});
kappa = log2(cat(1, kappa{:}));
ampl = cat(1, ampl{:});
ratio = log2(ampl ./ base);
base = log2(base);

% plot distribution of loadings
sem = @(x) std(x) / sqrt(numel(x));
for i = 1 : p
    figure(1000 + 100 * transformNum + 10 * zscore + i), clf
    M = 2; N = 3; K = 1;
    
    subplot(M, N, K); K = K + 1;
    baseBins = -4 : 2 : 6;
    plot(base, C(:, i), '.k', 'markersize', 3)
    xlabel('Baseline firing rate (spikes/s)')
    ylabel('Average factor loading')
    axisTight
    set(gca, 'box', 'off', 'xlim', baseBins([1 end]), 'xtick', baseBins, 'xticklabel', 2 .^ baseBins)

    subplot(M, N, K); K = K + 1;
    ratioBins = -5 : 2 : 8;
    plot(ratio, C(:, i), '.k', 'markersize', 3)
    xlabel('log2(Amplitude / baseline)')
    ylabel('Average factor loading')
    axisTight
    set(gca, 'box', 'off', 'xlim', ratioBins([1 end]), 'xtick', ratioBins, 'xticklabel', 2 .^ ratioBins)

    subplot(M, N, K); K = K + 1;
    kappaBins = -2 : 1 : 4;
    plot(kappa, C(:, i), '.k', 'markersize', 3)
    xlabel('Tuning sharpness [log2(kappa)]')
    ylabel('Average factor loading')
    axisTight
    set(gca, 'box', 'off', 'xlim', kappaBins([1 end]), 'xtick', kappaBins, 'xticklabel', 2 .^ kappaBins)

    subplot(M, N, K); K = K + 1;
    hold on
    [m, se, binc] = makeBinned(base, C(:, i), baseBins, @mean, sem, 'include');
    errorbar(binc, m, se, 'k')
    [m, se, binc] = makeBinned(base, C(:, i).^2, baseBins, @mean, sem, 'include');
    errorbar(binc + 0.1, m, se, '--k')
    xlabel('Baseline firing rate (spikes/s)')
    ylabel('Average factor loading')
    axisTight
    set(gca, 'box', 'off', 'xtick', baseBins, 'xticklabel', 2 .^ baseBins)

    subplot(M, N, K); K = K + 1;
    hold on
    [m, se, binc] = makeBinned(ratio, C(:, i), ratioBins, @mean, sem, 'include');
    errorbar(binc, m, se, 'k')
    [m, se, binc] = makeBinned(ratio, C(:, i).^2, ratioBins, @mean, sem, 'include');
    errorbar(binc + 0.1, m, se, '--k')
    xlabel('log2(Amplitude / baseline)')
    ylabel('Average factor loading')
    axisTight
    set(gca, 'box', 'off', 'xtick', ratioBins, 'xticklabel', 2 .^ ratioBins)
    
    subplot(M, N, K); K = K + 1;
    hold on
    [m, se, binc] = makeBinned(kappa, C(:, i), kappaBins, @mean, sem, 'include');
    errorbar(binc, m, se, 'k')
    [m, se, binc] = makeBinned(kappa, C(:, i).^2, kappaBins, @mean, sem, 'include');
    errorbar(binc + 0.1, m, se, '--k')
    xlabel('Tuning sharpness (kappa)')
    ylabel('Average factor loading')
    axisTight
    set(gca, 'box', 'off', 'xtick', kappaBins, 'xticklabel', 2 .^ kappaBins)
end


function m = nanmean(x)
% Mean excluding NaNs (to avoid using stats toolbox)

[ni, nj, ~] = size(x);
m = zeros(ni, nj);
for i = 1 : ni
    m(i, :) = mean(x(i, :, ~isnan(x(i, 1, :))), 3);
end
