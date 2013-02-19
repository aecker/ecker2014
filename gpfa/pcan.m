function pca(byCond)

restrictions = 'subject_id in (9, 11) AND sort_method_num = 5 AND spike_count_end = 2030';

% build relation
if ~nargin || byCond
    rel = nc.PcaCond & restrictions;
else
    rel = nc.Pca & restrictions;
end

% some sanity checks
assert(numel(unique(fetchn(rel, 'sort_method_num'))) == 1, 'sort_method_num must be specified!')

V = fetchn(rel, 'all_pc');

% plot distribution of weights
rng(1)
figure(33), clf
p = 2;
M = p; N = 3; K = 1;
for i = 1 : p

    % distribution of PC weights sorted per site
    subplot(M, N, K); K = K + 1;
    Vi = cellfun(@(x) sort(x(:, i) * sign(mean(x(:, i))), 'descend'), V, 'uni', false);
    x = cellfun(@(x) linspace(0, 1, numel(x))' + 0.01 * randn(size(x)), Vi, 'uni', false);
    x = cat(1, x{:});
    Vi = cat(1, Vi{:});
    plot(x, Vi, '.k', 'markersize', 1)
    hold on
    bins = 0 : 0.1 : 1;
    [m, binc] = makeBinned(x, Vi, bins, @mean, 'include');
    plot(binc, m, 'r')
    set(gca, 'xlim', [-0.05 1.05], 'ylim', [-1 1], 'box', 'off', 'xtick', [0.1 0.9], 'xticklabel', {'strongest', 'weakest'})
    plot(xlim, [0 0], 'k')
    xlabel('Cells sorted by weight on PC')
    ylabel('PC weight')
    
    % overall distribution of weights
    subplot(M, N, K); K = K + 1;
    bins = -0.95 : 0.1 : 1;
    h = hist(Vi, bins);
    h = h / sum(h);
    bar(bins, h, 1, 'facecolor', 0.5 * ones(1, 3))
    hold on
    plot([0 0], ylim, '--k')
    xlabel('PC weight')
    ylabel('Fraction of cells')
    set(gca, 'xlim', [-1 1], 'box', 'off')
    
    % distribution of average weights per site
    subplot(M, N, K); K = K + 1;
    m = cellfun(@(x) abs(mean(x(:, i))), V);
    bins = -0.0125 : 0.025 : 0.275;
    h = hist(m, bins);
    h = h / sum(h);
    bar(bins, h, 1, 'facecolor', 0.5 * ones(1, 3))
    xlabel('Average PC weight')
    ylabel('Fraction of sites')
    set(gca, 'xlim', bins([1 end]), 'box', 'off')
end

