function covExplPairwise(varargin)
% Analyze how well the GPFA model approximates the covariance matrix.
%
%   For this analysis we look at the off-diagonals of the difference
%   between observed and predicted (by GPFA) covariance matrix.
%
%   It seems like there are a few large values. This is probably because
%   the Anscombe transformation isn't stabilizing the variances
%   sufficiently since the data is quite overdispersed compared to Poisson
%   even when modelling internal factors. We could probably consider
%   z-scoring the data before fitting the model. However, this may put too
%   much emphasis on low-firing rate cells. This needs to be explored
%   further.
%
% AE 2012-12-11

if ~nargin
    restrictions = {'subject_id in (9, 11)', ...
                    'sort_method_num = 5', ...
                    'transform_num = 2', ...
                    'kfold_cv = 2'};
else
    restrictions = varargin;
end

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

dtrain = differences(data, 'cov_train');
dtest = differences(data, 'cov_test');

% plot data
figure(20 + data(1).transform_num), clf

subplot(2, 2, 1)
plot(0 : pmax, sqrt(mean(mean(dtrain .^ 2, 3), 1)), '.-k')
xlim([-1 pmax + 1])
title('RMS difference')
set(legend('Training data'), 'box', 'off')
box off

subplot(2, 2, 2)
plot(0 : pmax, median(mean(abs(dtrain), 3), 1), '.-k')
xlim([-1 pmax + 1])
title('median absolute difference')
box off

subplot(2, 2, 3)
plot(0 : pmax, sqrt(mean(mean(dtest, 3), 1)), '.-r')
xlim([-1 pmax + 1])
xlabel('# latent factors')
set(legend('Test data'), 'box', 'off')
box off

subplot(2, 2, 4)
plot(0 : pmax, median(mean(abs(dtest), 3), 1), '.-r')
xlim([-1 pmax + 1])
xlabel('# latent factors')
box off



function d = differences(data, field)

offdiag = @(x) x(~tril(ones(size(x))));
[n, pmax, kfold] = size(data);
d = zeros(0, pmax);
for p = 1 : pmax
    for k = 1 : kfold
        dpk = cell(1, n);
        for i = 1 : n
            dpk{i} = offdiag(data(i, p, k).(field) - data(i, p, k).cov_pred);
        end
        dpk = cat(1, dpk{:});
        d(1 : numel(dpk), p, k) = dpk;
    end
end
