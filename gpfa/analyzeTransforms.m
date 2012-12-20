function analyzeTransforms()
% Evaluate performance of different transformations.
%   analyzeTransforms()
%
%   Here I compute the R^2 (variance explained) of the one-factor GPFA
%   model for each cell as a function of the various data transformations
%   that I used for fitting.
%   
% AE 2012-12-20

kfold = 2;
restrictions = {'subject_id IN (9, 11) AND sort_method_num = 5', struct('kfold_cv', kfold)};
latent = 'latent_dim = 1';

nTrans = count(nc.DataTransforms);
nUnits = count(nc.GpfaUnits & restrictions) / nTrans;
rsq = zeros(nTrans, nUnits);
tr = 1;

for transform = fetch(nc.DataTransforms)'
    unit = 1;
    for modelset = fetch(nc.GpfaModelSet & restrictions & transform, 'transformed_data')'
        rsqi = 0;
        for run = fetch(nc.GpfaModel & modelset & latent, 'model', 'test_set')'
            model = GPFA(run.model);
            Y = modelset.transformed_data(:, :, run.test_set);
            Ypred = model.predict(Y);
            Y = Y(1 : end, :)';
            Ypred = Ypred(1 : end, :)';
            rsqi = rsqi + mean(zscore(Y, 1) .* zscore(Ypred, 1), 1) .^ 2;
        end
        n = numel(rsqi);
        rsq(tr, unit + (1 : n)) = rsqi / kfold;
        unit = unit + n;
    end
    tr = tr + 1;
end

figure
bar(mean(rsq, 2), 0.5)
set(gca, 'xlim', [0 tr], 'xtick', 1 : tr - 1, 'box', 'off', ...
    'xticklabel', fetchn(nc.DataTransforms, 'name'))
