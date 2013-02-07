function factorLoadingUnitProps(transformNum, zscore, p)
% Correlate factor loadings with single unit properties.
%
% AE 2012-01-24

binSize = 100;
restrictions = {sprintf('subject_id in (9, 11) AND sort_method_num = 5 AND kfold_cv = 2 AND cv_run = 1 AND bin_size = %d AND latent_dim = %d', binSize, p), ...
                 struct('transform_num', transformNum, 'zscore', zscore)};

rel = nc.GpfaParams * nc.GpfaModelSet * nc.GpfaModel & restrictions;
[model, Y, train, keys] = fetchn(rel, 'model', 'transformed_data', 'train_set');

n = numel(model);
C = cell(n, 1);
rate = cell(n, 1);
fano = cell(n, 1);
for iModel = 1 : n
    % normalize latent factors
    model{iModel} = normFactors(GPFA(model{iModel}), Y{iModel}(:, :, train{iModel}));
    
    % order factors by variance explained
    Ci = model{iModel}.C;
    [~, order] = sort(sqrt(sum(Ci .^ 2, 1)), 'descend');    % sort by norm
    Ci = Ci(:, order);
    C{iModel} = bsxfun(@times, Ci, sign(median(Ci, 1)));           % sign flip
    
    % get unit properties
    propsRel = nc.GpfaUnits * nc.UnitStatsConditions & keys(iModel) & 'spike_count_end = 2030';
    [rate{iModel}, fano{iModel}] = fetchn(propsRel, 'mean_rate_cond', 'fano_cond');
end
C = cat(1, C{:});
rate = log2(cat(1, rate{:}));
fano = log2(cat(1, fano{:}));

% plot distribution of loadings
sem = @(x) std(x) / sqrt(numel(x));
for i = 1 : p
    figure(100 * transformNum + 10 * zscore + i), clf
    M = 2; N = 2; K = 1;
    
    subplot(M, N, K); K = K + 1;
    rateBins = -1 : 8;
    plot(rate, C(:, i), '.k', 'markersize', 1)
    xlabel('Mean firing rate (spikes/s)')
    ylabel('Average factor loading')
    axisTight
    set(gca, 'box', 'off', 'xtick', rateBins, 'xticklabel', 2 .^ rateBins)

    subplot(M, N, K); K = K + 1;
    fanoBins = -1 : 7;
    plot(fano, C(:, i), '.k', 'markersize', 1)
    xlabel('Fano factor')
    ylabel('Average factor loading')
    axisTight
    set(gca, 'box', 'off', 'xtick', fanoBins, 'xticklabel', 2 .^ fanoBins)

    subplot(M, N, K); K = K + 1;
    hold on
    [m, se, binc] = makeBinned(rate, C(:, i), rateBins, @mean, sem);
    errorbar(binc, m, se, 'k')
    [m, se, binc] = makeBinned(rate, C(:, i).^2, rateBins, @mean, sem);
    errorbar(binc + 0.1, m, se, '--k')
    xlabel('Mean firing rate (spikes/s)')
    ylabel('Average factor loading')
    axisTight
    set(gca, 'box', 'off', 'xtick', rateBins, 'xticklabel', 2 .^ rateBins)
    
    subplot(M, N, K); K = K + 1;
    hold on
    [m, se, binc] = makeBinned(fano, C(:, i), fanoBins, @mean, sem);
    errorbar(binc, m, se, 'k')
    [m, se, binc] = makeBinned(fano, C(:, i).^2, fanoBins, @mean, sem);
    errorbar(binc + 0.1, m, se, '--k')
    xlabel('Fano factor')
    ylabel('Average factor loading')
    axisTight
    set(gca, 'box', 'off', 'xtick', fanoBins, 'xticklabel', 2 .^ fanoBins)
end
