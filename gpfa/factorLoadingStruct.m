function factorLoadingStruct(varargin)
% Structure of factor loadings.
%   factorLoadingStruct()
%
%   This function plots the structure of the factor loadings for a p-factor
%   model in various ways.
%
% AE 2012-01-22

% key for analysis parameters/subjects etc.
key.transform_num = 5;
key.zscore = false;
key.sort_method_num = 5;
key.bin_size = 100;
key.max_latent_dim = 1;
key.latent_dim = 1;
key.max_instability = 0.1;
key.kfold_cv = 1;
key.spike_count_end = 530;
key = genKey(key, varargin{:});

% Compute variance explained
stateKeys = struct('state', {'awake', 'anesthetized'});
nStates = numel(stateKeys);

rng(1)
fig = Figure(1, 'size', [90 140]);
M = 3; N = nStates; K = 1;

for iState = 1 : nStates

    % obtain factor loadings
    rel = nc.Anesthesia * nc.GpfaParams * nc.GpfaModelSet * nc.GpfaModel & key & stateKeys(iState);
    [model, Y, train] = fetchn(rel, 'model', 'transformed_data', 'train_set');
    Ci = cellfun(@getLoadings, model, Y, train, 'uni', false);
    C = cat(1, Ci{:});
    
    % plot distribution of loadings
    subplot(M, N, K); K = K + 1;
    x = cellfun(@(C) linspace(0, 1, size(C, 1))', Ci, 'uni', false);
    x = cat(1, x{:});
    plot(x + randn(size(x)) / 50, C, '.k', 'markersize', 1)
    hold on
    bins = -0.025 : 0.05 : 1.025;
    [m, binc] = makeBinned(x, C, bins, @mean, 'include');
    plot(binc, m, 'color', colors(stateKeys(iState).state))
    set(gca, 'xlim', [-0.05 1.05], 'xtick', [0.1 0.9], 'xticklabel', {'weakest', 'strongest'}, 'ylim', [-1 1])
    plot(xlim, [0 0], 'k')
    if iState == nStates
        xlabel('Cells sorted by weight')
    end
    ylabel('Weight')
    axis square
    
    % overall distribution of loadings
    subplot(M, N, K); K = K + 1;
    bins = -0.325 : 0.05 : 0.65;
    h = hist(C, bins);
    h = h / sum(h);
    bar(bins, h, 1, 'facecolor', colors(stateKeys(iState).state), 'linestyle', 'none')
    hold on
    plot([0 0], ylim, '--k')
    if iState == nStates
        xlabel('Weight')
    end
    ylabel('Fraction of cells')
    set(gca, 'xlim', [-0.35 0.65], 'xtick', -0.3 : 0.3 : 0.6)
    axis square
    
    subplot(M, N, 5 : 6)
    bins = -0.3025 : 0.005 : 0.605;
    hold on
    hci = bootstrap(Ci, bins);
    c = 0.3 * colors(stateKeys(iState).state) + 0.7 * ones(1, 3);
    [x, y] = makePatch(bins + 0.0025, hci, [-0.3 0.6]);
    patch(x, y, c, 'linestyle', 'none');
    h = hist(C, bins);
    h = h / sum(h);
    plot(bins + 0.0025, cumsum(h), 'color', colors(stateKeys(iState).state))
end
set(gca, 'xlim', [-0.3 0.6], 'xtick', -0.3 : 0.1 : 0.6, 'ylim', [0 1.001]);
xlabel('Weight')
ylabel('Cumulative distribution')
plot([0 0], [0 1], '--k')

fig.cleanup();
file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save(file)


function C = getLoadings(model, Y, ndx)

model = GPFA(model);
model = model.normFactors(Y(:, :, ndx));
C = model.C;
C = C * sign(median(C));
C = sort(C);


function hci = bootstrap(Ci, bins)
% Bootstrap cumulative distribution using zero-mean Gaussian and sign flip

K = 1000;
N = numel(Ci);
Cr = cell(1, N);
for i = 1 : N
    C = Ci{i};
    C = bsxfun(@times, sign(randn(size(C, 1), K)), C);
    Cr{i} = bsxfun(@times, C, sign(median(C)));
end
Cr = cat(1, Cr{:});
h = hist(Cr, bins);
h = bsxfun(@rdivide, h, sum(h, 1));
hci = prctile(cumsum(h, 1), [5 95], 2);


function [x, y] = makePatch(bins, hci, xr)
% convert lower and upper confidence bands to (x, y) pairs for patch()

ndx = bins >= xr(1) & bins <= xr(2);
x = [bins(ndx), fliplr(bins(ndx))];
y = [hci(ndx, 1); flipud(hci(ndx, 2))]';

