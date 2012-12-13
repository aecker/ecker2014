function covResid(varargin)
% Analyze how well the GPFA model approximates the covariance matrix.
%
%   For this analysis we look at the covariance of the residuals after
%   accounting for internal state.
%
%   For this analysis we can use only one of the cross-validation runs
%   since training and test error add up to the same value if all runs are
%   averaged. This is of course not true if squares or average values are
%   averaged -- but that's not what we're interested in here.
%
% AE 2012-12-13

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

rtrain = residuals(data, 'cov_resid_train');
rtest = residuals(data, 'cov_resid_test');

% plot data
figure(30 + data(1).transform_num), clf

subplot(1, 2, 1)
plot(0 : pmax, mean(mean(rtrain, 3), 1), '.-k', ...
     0 : pmax, mean(mean(rtest, 3), 1), '.-r')
xlim([-1 pmax + 1])
ylabel('Mean residual covariance')
set(legend({'Training data', 'Test data'}), 'box', 'off')
box off

subplot(1, 2, 2)
plot(0 : pmax, std(mean(rtrain, 3), 1), '.-k', ...
     0 : pmax, std(mean(rtest, 3), 1), '.-r')
xlim([-1 pmax + 1])
ylabel('SD of residual covariance')
box off


function r = residuals(data, field)

offdiag = @(x) x(~tril(ones(size(x))));
[n, pmax, kfold] = size(data);
r = zeros(0, pmax);
for p = 1 : pmax
    for k = 1 : kfold
        rpk = cell(1, n);
        for i = 1 : n
            rpk{i} = offdiag(data(i, p, k).(field));
        end
        rpk = cat(1, rpk{:});
        r(1 : numel(rpk), p, k) = rpk;
    end
end
