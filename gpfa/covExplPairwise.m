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
% AE 2012-12-11

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

dtrain = differences(data, 'cov_train', coeff);
dtest = differences(data, 'cov_test', coeff);

% plot data
fig = sum([transformNum zscore byTrial coeff] .* 10 .^ (3 : -1 : 0));
figure(fig), clf

subplot(2, 1, 1)
plot(0 : pmax, sqrt(mean(mean(dtrain .^ 2, 3), 1)), '.-k', ...
     0 : pmax, sqrt(mean(mean(dtest .^ 2, 3), 1)), '.-r')
xlim([-1 pmax + 1])
title('RMS difference')
set(legend({'Training data', 'Test data'}), 'box', 'off')
box off

subplot(2, 1, 2)
plot(0 : pmax, median(mean(abs(dtrain), 3), 1), '.-k', ...
     0 : pmax, median(mean(abs(dtest), 3), 1), '.-r')
xlim([-1 pmax + 1])
title('median absolute difference')
box off



function d = differences(data, field, coeff)

offdiag = @(x) x(~tril(ones(size(x))));
corr = @(C) C ./ sqrt(diag(C) * diag(C)');
[n, pmax, kfold] = size(data);
d = zeros(0, pmax);
for p = 1 : pmax
    for k = 1 : kfold
        dpk = cell(1, n);
        for i = 1 : n
            if coeff    % convert to correlation coefficient?
                dpk{i} = offdiag(corr(data(i, p, k).(field)) - corr(data(i, p, k).cov_pred));
%                 dpk{i} = offdiag(corr(data(i, p, k).(strrep(field, '_', '_resid_'))));
            else
                dpk{i} = offdiag(data(i, p, k).(field) - data(i, p, k).cov_pred);
%                 dpk{i} = offdiag(data(i, p, k).(strrep(field, '_', '_resid_')));
            end
        end
        dpk = cat(1, dpk{:});
        d(1 : numel(dpk), p, k) = dpk;
    end
end
