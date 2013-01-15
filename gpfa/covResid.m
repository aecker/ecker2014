function covResid(varargin)
% OUTDATED -- check if still useful...

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
assert(numel(unique([data.detect_method_num])) == 1, 'detect_method_num must be unique!')
assert(numel(unique([data.sort_method_num])) == 1, 'sort_method_num must be unique!')
assert(numel(unique([data.bin_size])) == 1, 'bin_size must be unique!')
assert(numel(unique([data.kfold_cv])) == 1, 'kfold_cv must be unique!')
assert(numel(unique([data.transform_num])) == 1, 'transform_num must be unique!')

data = dj.struct.sort(data, {'cv_run', 'latent_dim', 'stim_start_time'});
data = reshape(data, [n / kfold, pmax + 1, kfold]);

[ctrain, rtrain] = residuals(data, 'cov_resid_train');
[ctest, rtest] = residuals(data, 'cov_resid_test');
[ctrainOrig, rtrainOrig] = residuals(data, 'cov_resid_raw_train');
[ctestOrig, rtestOrig] = residuals(data, 'cov_resid_raw_test');

% plot data
figure(30 + data(1).transform_num), clf
m = 4; n = 2; k = 1;

subplot(m, n, k); k = k + 1;
plot(0 : pmax, mean(mean(ctrain, 3), 1), '.-k', ...
     0 : pmax, mean(mean(ctest, 3), 1), '.-r')
xlim([-1 pmax + 1])
ylabel('Mean residual covariance')
set(legend({'Training data', 'Test data'}), 'box', 'off')
box off

subplot(m, n, k); k = k + 1;
plot(0 : pmax, std(mean(ctrain, 3), 1), '.-k', ...
     0 : pmax, std(mean(ctest, 3), 1), '.-r')
xlim([-1 pmax + 1])
ylabel('SD of residual covariance')
box off

subplot(m, n, k); k = k + 1;
plot(0 : pmax, mean(mean(rtrain, 3), 1), '.-k', ...
     0 : pmax, mean(mean(rtest, 3), 1), '.-r')
xlim([-1 pmax + 1])
ylabel('Mean residual corrcoef')
set(legend({'Training data', 'Test data'}), 'box', 'off')
box off

subplot(m, n, k); k = k + 1;
plot(0 : pmax, std(mean(rtrain, 3), 1), '.-k', ...
     0 : pmax, std(mean(rtest, 3), 1), '.-r')
xlim([-1 pmax + 1])
ylabel('SD of residual corrcoef')
box off

subplot(m, n, k); k = k + 1;
plot(0 : pmax, mean(mean(ctrainOrig, 3), 1), '.-k', ...
     0 : pmax, mean(mean(ctestOrig, 3), 1), '.-r')
xlim([-1 pmax + 1])
ylabel('Mean residual covariance')
set(legend({'Training data', 'Test data'}), 'box', 'off')
box off

subplot(m, n, k); k = k + 1;
plot(0 : pmax, std(mean(ctrainOrig, 3), 1), '.-k', ...
     0 : pmax, std(mean(ctestOrig, 3), 1), '.-r')
xlim([-1 pmax + 1])
ylabel('SD of residual covariance')
box off

subplot(m, n, k); k = k + 1;
plot(0 : pmax, mean(mean(rtrainOrig, 3), 1), '.-k', ...
     0 : pmax, mean(mean(rtestOrig, 3), 1), '.-r')
xlim([-1 pmax + 1])
ylabel('Mean residual corrcoef')
set(legend({'Training data', 'Test data'}), 'box', 'off')
box off

subplot(m, n, k);
plot(0 : pmax, std(mean(rtrainOrig, 3), 1), '.-k', ...
     0 : pmax, std(mean(rtestOrig, 3), 1), '.-r')
xlim([-1 pmax + 1])
ylabel('SD of residual corrcoef')
box off


function [c, r] = residuals(data, field)

offdiag = @(x) x(~tril(ones(size(x))));
[n, pmax, kfold] = size(data);
c = zeros(0, pmax);
r = zeros(0, pmax);
for p = 1 : pmax
    for k = 1 : kfold
        cpk = cell(1, n);
        rpk = cell(1, n);
        for i = 1 : n
            C = data(i, p, k).(field);
            R = C ./ sqrt(diag(C) * diag(C)');
            cpk{i} = offdiag(C);
            rpk{i} = offdiag(R);
        end
        cpk = cat(1, cpk{:});
        rpk = cat(1, rpk{:});
        c(1 : numel(cpk), p, k) = cpk;
        r(1 : numel(rpk), p, k) = rpk;
    end
end
