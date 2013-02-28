function analyzeTransforms(varargin)
% Evaluate performance of different transformations.
%   analyzeTransforms('name', value, ...)
%
%   Here I compute percent variance explained on the test set for the one-
%   factor GPFA model for each cell as a function of the various data
%   transformations that I used for fitting.
%   
% AE 2012-02-27

% key for analysis parameters/subjects etc.
key.subject_id = [9 11];
key.sort_method_num = 5;
key.bin_size = 100;
key.max_latent_dim = 1;
key.latent_dim = 1;
key.min_stability = 0.1;
key.kfold_cv = 2;
key.by_trial = false;
key = genKey(key, varargin{:});

binSize = unique([key.bin_size]);
assert(isscalar(binSize), 'binSize must be specified uniquely!')

nTrans = count(nc.DataTransforms);
nUnits = count(nc.GpfaParams * nc.GpfaUnits & key) / nTrans / 2;
ve = zeros(nUnits, nTrans, 2);
fr = zeros(nUnits, nTrans, 2);
tr = 1;

% Compute variance explained for different transforms
for transform = fetch(nc.DataTransforms)'
    for z = [0 1]
        modelKey = dj.struct.join(struct('zscore', z), key);
        modelKey = dj.struct.join(modelKey, transform);
        rel = nc.GpfaParams * nc.GpfaModelSet * nc.GpfaVarExpl * nc.UnitStatsConditions & modelKey;
        [ve(:, tr, z + 1), fr(:, tr, z + 1)] = fetchn(rel, '1 - var_unexpl_test -> v', 'mean_rate_cond');
    end
    tr = tr + 1;
end
fr = log2(fr);

% scatter plots: R^2 vs. firing rate
bins = -1 : 7;
for z = 1 : 2
    figure(10 + z), clf
    for i = 1 : nTrans
        subplot(2, 2, i)
        plot(fr(:, i, z), ve(:, i, z), '.k', 'markersize', 1)
        hold on
        [m, binsc] = makeBinned(fr(:, i, z), ve(:, i, z), bins, @mean, 'include');
        plot(binsc, m, '*-r')
        axis tight
        set(gca, 'box', 'off', 'xtick', bins, 'xticklabel', 2 .^ bins)
    end
end

% Summary plot
%   (a) average R^2 for the different transforms
%   (b) average R^2 as a function of firing rate as well
figure(3 + key(1).by_trial), clf
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
linestyle = {'-', '--'};
for i = 1 : nTrans
    for z = 1 : 2
        m = makeBinned(fr(:, i, z), ve(:, i, z), bins, @mean, 'include');
        plot(binsc, m, linestyle{z}, 'color', colors(i, :))
    end
end
set(gca, 'box', 'off', 'xlim', bins([1 end]), 'xtick', bins, 'xticklabel', 2 .^ bins)
ylabel('Average R^2')
xlabel('Average firing rate (spikes/s)')

% Statistics: are the differences between transformation significant?
tr = 1;
nModels = count(nc.GpfaParams * nc.GpfaModelSet & key) / nTrans / 2;
vea = zeros(nModels, 2, nTrans);
for transform = fetch(nc.DataTransforms)'
    for z = [0 1]
        modelKey = dj.struct.join(struct('zscore', z), key);
        modelKey = dj.struct.join(modelKey, transform);
        vea(:, z + 1, tr) = fetchn(nc.GpfaParams * nc.GpfaCovExpl & modelKey, '1 - avg_var_unexpl_train -> v');
    end
    tr = tr + 1;
end

[p, ~, stats] = friedman(vea(1 : end, :));
multcompare(stats);
fprintf('Friedman test: p = %.2g\n\n', p)
