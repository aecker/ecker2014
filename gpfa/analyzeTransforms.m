function analyzeTransforms()
% Evaluate performance of different transformations.
%   analyzeTransforms()
%
%   Here I compute the R^2 (variance explained) of the one-factor GPFA
%   model for each cell as a function of the various data transformations
%   that I used for fitting.
%
%   * The differences between the transforms aren't too big (ca. 10%)
%   * Anscombe transform and log(x + 1) perform best
%   * R^2 is larger for higher firing rates. This is particularly strong
%       for the untransformed data. It seems like the model puts most of
%       its weight here on explaining the high-firing-rate cells. This is
%       of course also somewhat of a concern for the other transforms if
%       variances are still higher there for high-firing cells.
%
%   TODO: look also at z-scored data, which eliminates the concern that the
%         high firing rates dominate. Of course this has the opposite
%         concern that sparsely firing cells' variances will be blown up.
%   
% AE 2012-12-21

kfold = 2;
restrictions = {'subject_id IN (9, 11) AND sort_method_num = 5', struct('kfold_cv', kfold)};
latent = 'latent_dim = 1';

nTrans = count(nc.DataTransforms);
nUnits = count(nc.GpfaUnits & restrictions) / nTrans;
rsq = zeros(nTrans, nUnits);
mfr = zeros(nTrans, nUnits);
tr = 1;

% Compute R^2 for different transforms
for transform = fetch(nc.DataTransforms)'
    unit = 0;
    for modelset = fetch(nc.GpfaModelSet & restrictions & transform, 'transformed_data', 'raw_data', 'bin_size')'
        rsqi = 0;
        mfri = 0;
        for run = fetch(nc.GpfaModel & modelset & latent, 'model', 'test_set')'
            model = GPFA(run.model);
            Y = modelset.transformed_data(:, :, run.test_set);
            Ypred = model.predict(Y);
            Y = Y(1 : end, :)';
            Ypred = Ypred(1 : end, :)';
            rsqi = rsqi + mean(zscore(Y, 1) .* zscore(Ypred, 1), 1) .^ 2;
            Yraw = modelset.raw_data(:, :, run.test_set);
            mfri = mfri + 1000 / modelset.bin_size * mean(mean(Yraw, 2), 3)';
        end
        n = numel(rsqi);
        rsq(tr, unit + (1 : n)) = rsqi / kfold;
        mfr(tr, unit + (1 : n)) = mfri / kfold;
        unit = unit + n;
    end
    tr = tr + 1;
end

% scatter plots: R^2 vs. firing rate
figure(1), clf
bb = -0.5 : 0.5 : 2.5;
bins = 10 .^ bb;
binsc = 10 .^ (bb(1 : end - 1) + diff(bb(1 : 2)) / 2);
for i = 1 : nTrans
    subplot(2, 2, i)
    plot(mfr(i, :), rsq(i, :), '.k', 'markersize', 1)
    hold on
    [~, bin] = histc(mfr(i, :), bins);
    m = accumarray(bin', rsq(i, :)', [numel(bins) - 1, 1], @mean);
    plot(binsc, m, '*-r') 
    set(gca, 'xscale', 'log', 'yscale', 'linear', 'box', 'off')
    axis tight
end

% Summary plot
%   (a) average R^2 for the different transforms
%   (b) average R^2 as a function of firing rate as well
figure(2), clf
subplot(2, 1, 1), hold all
colors = colormap(lines);
for i = 1 : nTrans
    bar(i, mean(rsq(i, :)), 0.5, 'facecolor', colors(i, :))
end
set(gca, 'xlim', [0 tr], 'xtick', 1 : tr - 1, 'box', 'off', ...
    'xticklabel', fetchn(nc.DataTransforms, 'name'))
ylabel('Average R^2')
subplot(2, 1, 2), hold all
for i = 1 : nTrans
    [~, bin] = histc(mfr(i, :), bins);
    m = accumarray(bin', rsq(i, :)', [numel(bins) - 1, 1], @mean);
    plot(binsc, m, '.-', 'color', colors(i, :)) 
end
set(gca, 'xscale', 'log', 'yscale', 'linear', 'box', 'off', 'xlim', [0.5 200])
set(gca, 'xticklabel', get(gca, 'xtick'))
ylabel('Average R^2')
xlabel('Average firing rate (spikes/s)')

