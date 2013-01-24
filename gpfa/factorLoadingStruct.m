function factorLoadingStruct(transformNum, zscore, p)
% Structure of factor loadings.
%   factorLoadingStruct(transformNum, zscore, p)
%
%   This function plots the structure of the factor loadings for a p-factor
%   model in various ways.
%
% AE 2012-01-22

binSize = 100;
restrictions = {sprintf('subject_id in (9, 11) AND sort_method_num = 5 AND kfold_cv = 2 AND cv_run = 1 AND bin_size = %d AND latent_dim = %d', binSize, p), ...
                 struct('transform_num', transformNum, 'zscore', zscore)};

rel = nc.GpfaModelSet * nc.GpfaModel & restrictions;
[model, Y, train] = fetchn(rel, 'model', 'transformed_data', 'train_set');

% normalize latent factors
normalize = @(model, Y, ndx) normFactors(GPFA(model), Y(:, :, ndx));
model = cellfun(normalize, model, Y, train, 'uni', false);

% order factors by variance explained
n = numel(model);
C = cell(n, 1);
for i = 1 : n
    Ci = model{i}.C;
    [~, order] = sort(sqrt(sum(Ci .^ 2, 1)), 'descend');    % sort by norm
    Ci = Ci(:, order);
    Ci = bsxfun(@times, Ci, sign(median(Ci, 1)));           % sign flip
    C{i} = sort(Ci, 'descend');                             % sort neurons
end
Call = cat(1, C{:});

% plot distribution of loadings
rng(1)
figure(100 * transformNum + 10 * zscore + p), clf
M = p; N = 3; K = 1;

for i = 1 : p

    % distribution of loadings sorted per site
    subplot(M, N, K); K = K + 1;
    x = cellfun(@(C) linspace(0, 1, size(C, 1))', C, 'uni', false);
    x = cat(1, x{:});
    plot(x + randn(size(x)) / 100, Call(:, i), '.k', 'markersize', 1)
    hold on
    bins = -0.025 : 0.05 : 1.025;
    binc = bins(1 : end - 1) + diff(bins(1 : 2)) / 2;
    [~, bin] = histc(x, bins);
    m = accumarray(bin, Call(:, i), [numel(bins) - 1, 1], @mean);
    plot(binc, m, 'r')
    set(gca, 'xlim', [-0.05 1.05], 'box', 'off', 'xtick', [0.1 0.9], 'xticklabel', {'strongest', 'weakest'})
    plot(xlim, [0 0], 'k')
    xlabel('Cells sorted by factor loadings')
    ylabel('Factor loading')
    
    % overall distribution of loadings
    subplot(M, N, K); K = K + 1;
    bins = -1 : 0.05 : 1;
    binc = bins(1 : end - 1) + diff(bins(1 : 2)) / 2;
    h = hist(Call(:, i), bins);
    h = h(1 : end - 1) / sum(h);
    bar(binc, h, 1, 'facecolor', 0.5 * ones(1, 3))
    hold on
    plot([0 0], ylim, '--k')
    xlabel('Factor loading')
    ylabel('Fraction of cells')
    set(gca, 'xlim', [-1 1], 'box', 'off')
    
    % distribution of average loadings per site
    subplot(M, N, K); K = K + 1;
    m = cellfun(@(C) abs(mean(C(:, i))), C);
    bins = 0 : 0.0125 : 0.4;
    binc = bins(1 : end - 1) + diff(bins(1 : 2)) / 2;
    h = histc(m, bins);
    h = h(1 : end - 1) / sum(h);
    bar(binc, h, 1, 'facecolor', 0.5 * ones(1, 3))
    xlabel('Average factor loading')
    ylabel('Fraction of sites')
    set(gca, 'xlim', [0, bins(end)], 'box', 'off')
end
