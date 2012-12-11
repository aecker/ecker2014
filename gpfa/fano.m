function fano(varargin)
% Analysis of Fano factors as a function of number of internal factors
% AE 2012-12-07
% !!! OUTDATED. works with rev. 325c7e9 !!!

if ~nargin
    restrictions = {'subject_id in (9, 11)', ...
                    'sort_method_num = 5', ...
                    'transform_num = 2'};
else
    restrictions = varargin;
end

rel = (nc.GpfaModel * nc.DataTransforms) & restrictions;
pmax = max(fetchn(rel, 'latent_dim'));
v = zeros(0, pmax + 1);
s = zeros(0, 1);
c = zeros(0, pmax + 1);

keys = fetch(rel & 'latent_dim = 1');
for key = keys'
    
    % reconstruct original spike count matrix
    [model, psth, inverse] = fetch1(rel & key, 'model', 'psth', 'inverse');
    Y = bsxfun(@plus, model.Y, psth); %#ok  % add average response
    Y = eval(strrep(inverse, 'x', 'Y'));    % invert transformation
    
    k = size(Y, 1);
    if k < 10, continue, end
    s(end + (1 : k), 1) = mean(Y(1 : k, :), 2);
    v(end + (1 : k), 1) = var(model.Y(1 : k, :), [], 2);
    C = corrcoef(model.Y(1 : k, :)');
    c(end + (1 : k * (k - 1) / 2), 1) = C(~tril(ones(size(C))));
    
    % compute variances after accounting for increasing number of factors
    pkey = rmfield(key, 'latent_dim');
    pmax = max(fetchn(rel & pkey, 'latent_dim'));
    v(end - k + 1 : end, pmax + 1 : end) = NaN;
    for p = 1 : pmax
        pkey.latent_dim = p;
        model = GPFA(fetch1(rel & pkey, 'model'));
        Yres = model.resid(model.Y);
        v(end - k + 1 : end, p + 1) = var(Yres(1 : k, :), [], 2);
        C = corrcoef(Yres(1 : k, :)');
        c(end - k * (k - 1) / 2 + 1 : end, p + 1) = C(~tril(ones(size(C))));
    end
end


%% plot percent variance explained
figure(1), clf, hold all
pmax = size(v, 2);
bins = 0 : 0.5 : 5;
for p = 2 : pmax
    [~, bin] = histc(sqrt(s), bins);
    vem = accumarray(bin, (v(:, 1) - v(:, p)) ./ v(:, 1), [numel(bins) 1], @nanmean);
    vese = accumarray(bin, (v(:, 1) - v(:, p)) ./ v(:, 1), [numel(bins) 1], @(x) nanstd(x) / sqrt(sum(~isnan(x))));
    errorbar(bins + diff(bins(1 : 2)) / 2, vem, vese, '.-')
    xlabel('sqrt(avg spike count)')
    ylabel('Fraction variance explained')
    xlim(bins([1 end]))
end


%% plot correlation histograms
figure(2), clf
bins = -1 : 0.01 : 1;
k = 3;
for p = 1 : k
    subplot(k, 1, p)
    hist(c(:, p), bins)
    xlim(0.2 * [-1 1])
    ax = axis;
    text(ax(1), 0.95 * ax(4), sprintf('   p = %d', p - 1), 'VerticalAlignment', 'top')
    if p == k
        xlabel('Noise correlation')
    end
end

