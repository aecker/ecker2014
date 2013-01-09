function analyzeTransforms(byTrial)
% Evaluate performance of different transformations.
%   analyzeTransforms()
%
%   Here I compute the R^2 between predicted and observed data for the
%   one-factor GPFA model for each cell as a function of the various data
%   transformations that I used for fitting.
%   
% AE 2012-01-08

% use spike counts for entire trial or each bin?
if ~nargin
    byTrial = false;
end

kfold = 2;
restrictions = {'subject_id IN (9, 11) AND sort_method_num = 5', struct('kfold_cv', kfold)};
latent = 'latent_dim = 1';

nTrans = count(nc.DataTransforms);
nUnits = count(nc.GpfaUnits & restrictions) / nTrans / 2;
rsq = zeros(nUnits, nTrans, 2);
mfr = zeros(nUnits, nTrans, 2);
tr = 1;

% Compute R^2 for different transforms
for transform = fetch(nc.DataTransforms)'
    for z = [0 1]
        unit = 0;
        for modelset = fetch(nc.GpfaModelSet & restrictions & transform & struct('zscore', z), ...
                'transformed_data', 'raw_data', 'bin_size')'
            rsqi = 0;
            mfri = 0;
            for run = fetch(nc.GpfaModel & modelset & latent, 'model', 'test_set')'
                model = GPFA(run.model);
                Y = modelset.transformed_data(:, :, run.test_set);
                Ypred = model.predict(Y);
                if byTrial
                    Y = permute(sum(Y, 2), [3 1 2]); 
                    Ypred = permute(sum(Ypred, 2), [3 1 2]); 
                else
                    Y = Y(1 : end, :)';
                    Ypred = Ypred(1 : end, :)';
                end
                rsqi = rsqi + mean(zscore(Y, 1) .* zscore(Ypred, 1), 1) .^ 2;
                Yraw = modelset.raw_data(:, :, run.test_set);
                mfri = mfri + 1000 / modelset.bin_size * mean(mean(Yraw, 2), 3)';
            end
            n = numel(rsqi);
            rsq(unit + (1 : n), tr, z + 1) = rsqi / kfold;
            mfr(unit + (1 : n), tr, z + 1) = mfri / kfold;
            unit = unit + n;
        end
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
        plot(mfr(:, i, z), rsq(:, i, z), '.k', 'markersize', 1)
        hold on
        [~, bin] = histc(mfr(:, i, z), bins);
        m = accumarray(bin, rsq(:, i, z), [numel(bins) - 1, 1], @mean);
        plot(binsc, m, '*-r')
        set(gca, 'xscale', 'log', 'yscale', 'linear', 'box', 'off')
        axis tight
    end
end

% Summary plot
%   (a) average R^2 for the different transforms
%   (b) average R^2 as a function of firing rate as well
figure(2), clf
subplot(2, 1, 1), hold all
colors = colormap(lines);
for i = 1 : nTrans
    for z = 1 : 2
        bar((i - 1) * 2 + z, mean(rsq(:, i, z)), 0.5, 'facecolor', colors(i, :))
    end
end
set(gca, 'xlim', [0, 2 * tr - 1], 'xtick', 1.5 : 2 : 2 * (tr - 1), 'box', 'off', ...
    'xticklabel', fetchn(nc.DataTransforms, 'name'))
ylabel('Average R^2')
subplot(2, 1, 2), hold all
linestyle = {'.-', '.--'};
for i = 1 : nTrans
    for z = 1 : 2
        [~, bin] = histc(mfr(:, i, z), bins);
        m = accumarray(bin, rsq(:, i, z), [numel(bins) - 1, 1], @mean);
        plot(binsc, m, linestyle{z}, 'color', colors(i, :))
    end
end
set(gca, 'xscale', 'log', 'yscale', 'linear', 'box', 'off', 'xlim', [0.5 200])
set(gca, 'xticklabel', get(gca, 'xtick'))
ylabel('Average R^2')
xlabel('Average firing rate (spikes/s)')

