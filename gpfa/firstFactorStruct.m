function firstFactorStruct(transformNum, zscore)
% Structure of first factor.
%   firstFactorStruct(transformNum, zscore)
%
%   This function plots the structure of the first latent factor in various
%   ways.
%
% AE 2012-01-22

binSize = 100;
restrictions = {sprintf('subject_id in (9, 11) AND sort_method_num = 5 AND kfold_cv = 2 AND cv_run = 1 AND bin_size = %d AND latent_dim = 1', binSize), ...
                 struct('transform_num', transformNum, 'zscore', zscore)};

rel = nc.GpfaModel & restrictions;
model = fetchn(rel, 'model');

% plot distribution of loadings
rng(1)
figure(10 * transformNum + zscore), clf
M = 1; N = 3; K = 1;

% distribution of loadings sorted per site
subplot(M, N, K); K = K + 1;
C = cellfun(@(x) sort(x.C * sign(median(x.C)), 'descend'), model, 'uni', false);
hold on
cellfun(@(x) plot(linspace(0, 1, numel(x)) + 0.01 * randn(1, numel(x)), x, '.k', 'markersize', 1), C)
set(gca, 'xlim', [-0.05 1.05], 'box', 'off', 'xtick', [0.1 0.9], 'xticklabel', {'strongest', 'weakest'})
plot(xlim, [0 0], 'k')
xlabel('Cells sorted by factor loadings')
ylabel('Factor loading')

% overall distribution of loadings
subplot(M, N, K); K = K + 1;
C2 = cat(1, C{:});
bins = -1 : 0.1 : 1;
binc = bins(1 : end - 1) + diff(bins(1 : 2)) / 2;
h = hist(C2, bins);
h = h(1 : end - 1) / sum(h);
bar(binc, h, 1, 'facecolor', 0.5 * ones(1, 3))
hold on
plot([0 0], ylim, '--k')
xlabel('Factor loading')
ylabel('Fraction of cells')
set(gca, 'xlim', [-1 1], 'box', 'off')

% distribution of average loadings per site
subplot(M, N, K); K = K + 1;
m = cellfun(@(x) abs(mean(x.C)), model);
bins = 0 : 0.025 : 0.4;
binc = bins(1 : end - 1) + diff(bins(1 : 2)) / 2;
h = histc(m, bins);
h = h(1 : end - 1) / sum(h);
bar(binc, h, 1, 'facecolor', 0.5 * ones(1, 3))
xlabel('Average factor loading')
ylabel('Fraction of sites')
set(gca, 'xlim', [0, bins(end)], 'box', 'off')
