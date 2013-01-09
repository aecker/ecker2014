function covExplPairwise(transformNum, zscore, byTrial, coeff)
% Analyze how well the GPFA model approximates the covariance matrix.
%   covExplPairwise(transformNum, zscore, byTrial, coeff) where
%   transformNum, zscore, and byTrial define which model should be used and
%   coeff indicates whether or not the differences are taken on the
%   covariances or correlation coefficients.
%
%   For this analysis we look at the off-diagonals of the difference
%   between observed and predicted (by GPFA) covariance matrix.
%
% AE 2013-01-09

restrictions = {'subject_id in (9, 11) AND sort_method_num = 5 AND kfold_cv = 2', ...
                 struct('transform_num', transformNum, 'zscore', zscore, 'by_trial', byTrial)};

rel = nc.GpfaCovExpl & restrictions;
n = count(rel & 'latent_dim = 0');
pmax = count(rel) / n - 1;
data = fetch(rel, '*');
kfold = data(1).kfold_cv;

% some sanity checks
assert(numel(unique([data.sort_method_num])) == 1, 'sort_method_num must be specified!')
assert(numel(unique([data.bin_size])) == 1, 'bin_size must be specified!')
assert(numel(unique([data.kfold_cv])) == 1, 'kfold_cv must be specified!')
assert(numel(unique([data.transform_num])) == 1, 'transform_num must be specified!')

data = dj.struct.sort(data, {'cv_run', 'latent_dim', 'stim_start_time'});
data = reshape(data, [n / kfold, pmax + 1, kfold]);

% convert to correlation coefficients?
if coeff
    convert = @(C) C ./ sqrt(diag(C) * diag(C)');
else
    convert = @(C) C;
end

% residual cov/corr
restrain = collect(data, @(data) convert(data.cov_resid_train));
restest = collect(data, @(data) convert(data.cov_resid_test));

% differences between predicted and observed
fun = @(data, field) convert(data.(field)) - convert(data.cov_pred);
dtrain = collect(data, @(data) fun(data, 'cov_train'));
dtest = collect(data, @(data) fun(data, 'cov_test'));

% plot data
fig = sum([transformNum zscore byTrial coeff] .* 10 .^ (3 : -1 : 0));
figure(fig), clf
ttext = {'covariance', 'corrcoef'};

subplot(2, 2, 1)
plot(0 : pmax, sqrt(mean(mean(dtrain .^ 2, 3), 1)), '.-k', ...
     0 : pmax, sqrt(mean(mean(dtest .^ 2, 3), 1)), '.-r')
xlim([-1 pmax + 1])
title('RMS')
ylabel(['Diff of ' ttext{coeff + 1} 's'])
set(legend({'Training data', 'Test data'}), 'box', 'off')
box off

subplot(2, 2,2)
plot(0 : pmax, median(mean(abs(dtrain), 3), 1), '.-k', ...
     0 : pmax, median(mean(abs(dtest), 3), 1), '.-r')
xlim([-1 pmax + 1])
title('Median absolute')
box off

subplot(2, 2, 3)
plot(0 : pmax, sqrt(mean(mean(restrain .^ 2, 3), 1)), '.-k', ...
     0 : pmax, sqrt(mean(mean(restest .^ 2, 3), 1)), '.-r')
xlim([-1 pmax + 1])
ylabel(['Residual ' ttext{coeff + 1}])
set(legend({'Training data', 'Test data'}), 'box', 'off')
box off

subplot(2, 2, 4)
plot(0 : pmax, median(mean(abs(restrain), 3), 1), '.-k', ...
     0 : pmax, median(mean(abs(restest), 3), 1), '.-r')
xlim([-1 pmax + 1])
box off



function d = collect(data, fun)

offdiag = @(x) x(~tril(ones(size(x))));
[n, pmax, kfold] = size(data);
d = zeros(0, pmax);
for p = 1 : pmax
    for k = 1 : kfold
        dpk = cell(1, n);
        for i = 1 : n
            dpk{i} = offdiag(fun(data(i, p, k)));
        end
        dpk = cat(1, dpk{:});
        d(1 : numel(dpk), p, k) = dpk;
    end
end
