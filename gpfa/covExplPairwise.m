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
fun = @(data, a, b) convert(data.(a)) - convert(data.(b));
dpredtrain = collect(data, @(data) fun(data, 'cov_train', 'cov_pred'));
dpredtest = collect(data, @(data) fun(data, 'cov_test', 'cov_pred'));
dtraintest = collect(data, @(data) fun(data, 'cov_train', 'cov_test'));

% plot data
fig = sum([transformNum zscore byTrial coeff] .* 10 .^ (3 : -1 : 0));
figure(fig), clf
ttext = {'covariance', 'corrcoef'};

subplot(1, 3, 1)
plot(0 : pmax, mean(mean(restrain, 3), 1), '.-k', ...
     0 : pmax, mean(mean(restest, 3), 1), '.-r')
xlim([-1 pmax + 1])
xlabel('# latent factors')
ylabel(['Mean residual ' ttext{coeff + 1}])
set(legend({'Training data', 'Test data'}), 'box', 'off')
box off

subplot(1, 3, 2)
plot(0 : pmax, std(mean(restrain, 3), [], 1), '.-k', ...
     0 : pmax, std(mean(restest, 3), [], 1), '.-r')
xlim([-1 pmax + 1])
xlabel('# latent factors')
ylabel(['SD of residual ' ttext{coeff + 1}])
box off

subplot(1, 3, 3)
plot(0 : pmax, sqrt(mean(mean(dpredtrain .^ 2, 3), 1)), '.-k', ...
     0 : pmax, sqrt(mean(mean(dpredtest .^ 2, 3), 1)), '.-r', ...
     0 : pmax, sqrt(mean(mean(dtraintest .^ 2, 3), 1)), '--k')
xlim([-1 pmax + 1])
xlabel('# latent factors')
ylabel(['RMS diff of ' ttext{coeff + 1} 's'])
legend({'pred - train', 'pred - test', 'train - test'})
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
