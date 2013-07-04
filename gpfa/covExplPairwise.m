function covExplPairwise(varargin)
% Analyze how well the GPFA model approximates the covariance matrix.
%   For this analysis we look at the off-diagonals of the difference
%   between observed and predicted (by GPFA) covariance matrix.
%
% AE 2013-01-09

% key for analysis parameters/subjects etc.
key.transform_num = 5;
key.zscore = false;
key.by_trial = false;
key.sort_method_num = 5;
key.bin_size = 100;
key.max_latent_dim = 10;
key.max_instability = 0.1;
key.kfold_cv = 2;
key = genKey(key, varargin{:});
assert(isscalar(key) && ~any(cellfun(@isempty, varargin(2 : 2 : end))), 'Parameters not unique!')

% Compute variance explained
stateKeys = struct('state', {'awake', 'anesthetized', 'anesthetized'}, ...
                   'spike_count_end', {530 2030 530});
N = numel(stateKeys);

rel = nc.Anesthesia * nc.GpfaParams * nc.GpfaModelSet * nc.GpfaCovExpl & key & stateKeys(2);
n = count(rel & 'latent_dim = 0');
pmax = count(rel) / n - 1;
data = fetch(rel, 'corr_resid_train', 'corr_resid_test', ...
    'rmsd_corr_pred_train', 'rmsd_corr_pred_test', 'rmsd_corr_train_test', ...
    'ORDER BY latent_dim, stim_start_time');
data = reshape(data, [n, pmax + 1]);

% residual cov/corr
restrain = collect(data, 'corr_resid_train');
restest = collect(data, 'corr_resid_test');

% plot data
fig = Figure(1 + key.by_trial + 10 * key.zscore, 'size', [90 50]);

subplot(1, 2, 1)
plot(0 : pmax, mean(restrain), '.-k', 0 : pmax, mean(restest), '.-r')
xlim([-1 pmax + 1])
xlabel('# latent factors')
ylabel('Mean residual correlation')
legend({'Training data', 'Test data'})
axis square

subplot(1, 2, 2)
plot(0 : pmax, std(restrain), '.-k', 0 : pmax, std(restest), '.-r')
hold on
plot(0 : pmax, median(abs(bsxfun(@minus, restrain, median(restrain)))), '.--k', ...
     0 : pmax, median(abs(bsxfun(@minus, restest, median(restest)))), '.--r')
xlim([-1 pmax + 1])
xlabel('# latent factors')
ylabel('SD of residual corr')
axis square

fig.cleanup()


function d = collect(data, field)

[n, pmax] = size(data);
d = zeros(0, pmax);
for p = 1 : pmax
    dp = cell(1, n);
    for i = 1 : n
        dp{i} = offdiag(data(i, p).(field));
    end
    dp = cat(1, dp{:});
    d(1 : numel(dp), p) = dp;
end
