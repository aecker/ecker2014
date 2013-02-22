function analyzeTransforms(byTrial, varargin)
% Evaluate performance of different transformations.
%   analyzeTransforms(byTrial, 'name', value, ...)
%
%   Here I compute the R^2 between predicted and observed data for the
%   one-factor GPFA model for each cell as a function of the various data
%   transformations that I used for fitting.
%   
% AE 2012-02-21

% use spike counts for entire trial or each bin?
if ~nargin
    byTrial = true;
end

% key for analysis parameters/subjects etc.
key.subject_id = [9 11];
key.sort_method_num = 5;
key.bin_size = 100;
key.max_latent_dim = 1;
key.latent_dim = 1;
key.min_stability = 0.1;
key = genKey(key, varargin{:});

kfold = 2;
[key.kfold_cv] = deal(kfold);

binSize = unique([key.bin_size]);
assert(isscalar(binSize), 'binSize must be specified uniquely!')

nTrans = count(nc.DataTransforms);
nUnits = count(nc.GpfaParams * nc.GpfaUnits & key) / nTrans / 2;
ve = zeros(nUnits, nTrans, 2);
fr = zeros(nUnits, nTrans, 2);
tr = 1;
order = 'ORDER BY stim_start_time, condition_num';

% Compute R^2 for different transforms
for transform = fetch(nc.DataTransforms)'
    for z = [0 1]
        modelKey = dj.struct.join(struct('zscore', z), key);
        modelKey = dj.struct.join(modelKey, transform);

        % compute variance explained
        [model, Yr, Yt, test] = fetchn(nc.GpfaParams * nc.GpfaModelSet * nc.GpfaModel & modelKey, ...
            'model', 'raw_data', 'transformed_data', 'test_set', order);
        [vei, fri] = cellfun(@varianceExplained, model, Yr, Yt, test, 'uni', false);
        vei = cellfun(@(a, b) (a + b) / 2, vei(1 : 2 : end), vei(2 : 2 : end), 'uni', false);
        ve(:, tr, z + 1) = cat(1, vei{:});
        fri = cellfun(@(a, b) (a + b) / 2, fri(1 : 2 : end), fri(2 : 2 : end), 'uni', false);
        fr(:, tr, z + 1) = cat(1, fri{:});
    end
    tr = tr + 1;
end

% scatter plots: R^2 vs. firing rate
bb = -0.5 : 0.5 : 2.5;
bins = 10 .^ bb;
binsc = 10 .^ (bb(1 : end - 1) + diff(bb(1 : 2)) / 2);
for z = 1 : 2
    figure(10 + z), clf
    for i = 1 : nTrans
        subplot(2, 2, i)
        plot(fr(:, i, z), ve(:, i, z), '.k', 'markersize', 1)
        hold on
        [~, bin] = histc(fr(:, i, z), bins);
        m = accumarray(bin, ve(:, i, z), [numel(bins) - 1, 1], @mean);
        plot(binsc, m, '*-r')
        set(gca, 'xscale', 'log', 'yscale', 'linear', 'box', 'off')
        axis tight
    end
end

% Summary plot
%   (a) average R^2 for the different transforms
%   (b) average R^2 as a function of firing rate as well
figure(3), clf
subplot(2, 1, 1), hold all
colors = colormap(lines);
for i = 1 : nTrans
    for z = 1 : 2
        bar((i - 1) * 2 + z, mean(ve(:, i, z)), 0.5, 'facecolor', colors(i, :))
    end
end
set(gca, 'xlim', [0, 2 * tr - 1], 'xtick', 1.5 : 2 : 2 * (tr - 1), 'box', 'off', ...
    'xticklabel', fetchn(nc.DataTransforms, 'name'))
ylabel('Average R^2')
subplot(2, 1, 2), hold all
linestyle = {'.-', '.--'};
for i = 1 : nTrans
    for z = 1 : 2
        [~, bin] = histc(fr(:, i, z), bins);
        m = accumarray(bin, ve(:, i, z), [numel(bins) - 1, 1], @mean);
        plot(binsc, m, linestyle{z}, 'color', colors(i, :))
    end
end
set(gca, 'xscale', 'log', 'yscale', 'linear', 'box', 'off', 'xlim', [0.5 200])
set(gca, 'xticklabel', get(gca, 'xtick'))
ylabel('Average R^2')
xlabel('Average firing rate (spikes/s)')


% subfunction to compute variance explained and firing rates.
function [ve, fr] = varianceExplained(model, Yr, Yt, test)
    Yt = Yt(:, :, test);
    Yr = Yr(:, :, test);
    model = GPFA(model);
    X = model.estX(Yt);
    if byTrial
        ve = var(sum(X, 2)) * model.C .^ 2 ./ var(sum(Yt, 2), [], 3);
    else
        ve = var(X(:)) * model.C .^ 2 ./ var(Yt(1 : end, :), [], 2);
    end
    fr = mean(Yr(1 : end, :), 2) / binSize * 1000;
end

end
