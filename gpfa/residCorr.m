function residCorr(varargin)
% Residual correlations of GPFA model.
%   For this analysis we look at the off-diagonals of the residual
%   covariance matrix as a function of the number of latent dimensions.
%
% AE 2013-03-08

% key for analysis parameters/subjects etc.
key.transform_num = 5;
key.zscore = false;
key.by_trial = false;
key.sort_method_num = 5;
key.bin_size = 100;
key.max_latent_dim = 10;
key.min_stability = 0.1;
key.kfold_cv = 2;
key = genKey(key, varargin{:});
assert(isscalar(key) && ~any(cellfun(@isempty, varargin(2 : 2 : end))), 'Parameters not unique!')

stateKeys = struct('state', {'awake', 'anesthetized', 'anesthetized'}, ...
                   'spike_count_end', {530 2030 530});
N = numel(stateKeys);

p = [0 1 2 4 8];
latent = sprintf('latent_dim IN (%s-1)', sprintf('%d, ', p));
K = numel(p);

m = zeros(N, K);
s = zeros(N, K);
for iState = 1 : N
    stateKey = stateKeys(iState);
    
    rel = nc.Anesthesia * nc.GpfaParams * nc.GpfaModelSet * nc.GpfaCovExpl & key & stateKey;
    n = count(rel & 'latent_dim = 0');
    data = fetch(rel & latent, 'corr_resid_test', 'ORDER BY latent_dim, stim_start_time');
    data = reshape(data, [n, K]);
    resid = collect(data, 'corr_resid_test');
    m(iState, :) = mean(resid);
    s(iState, :) = std(resid);
end

% plot data
faceColors = {[0 0.4 1], 'r', 'w'};
lineStyles = {'none', 'none', '-'};
lineColors = {'k', 'k', 'r'};
switch key.by_trial
    case false
        ylm = 0.04;
        yls = 0.1;
    case true
        ylm = 0.1;
        yls = 0.2;
end
ind = 0.5;

fig = Figure(3 + key.by_trial + 10 * key.zscore, 'size', [90 45]);

subplot(1, 2, 1)
hold on
hdl(1, :) = bar(1 : K, m', 1);
axis square
set(gca, 'xlim', [ind, K + 1 - ind], 'ylim', [0 ylm], 'xtick', 1 : K, 'xticklabel', p)
xlabel('# latent factors')
ylabel('Mean residual correlation')
legend({'awake', 'anesthetized', 'anesth. 500 ms'})

subplot(1, 2, 2)
hdl(2, :) = bar(1 : K, s', 1);
axis square
set(gca, 'xlim', [ind, K + 1 - ind], 'ylim', [0 yls], 'xtick', 1 : K, 'xticklabel', p)
xlabel('# latent factors')
ylabel('SD of residual corr')

for i = 1 : N
    set(hdl(:, i), 'FaceColor', faceColors{i}, 'LineStyle', lineStyles{i}, 'EdgeColor', lineColors{i});
end

fig.cleanup()

byTrial = {'_bins', '_trials'};
file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save([file byTrial{key(1).by_trial + 1}])
pause(1)
fig.save([file byTrial{key(1).by_trial + 1} '.png'])


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
