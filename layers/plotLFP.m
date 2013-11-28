function plotLFP(subjectId, varargin)

if ~nargin, subjectId = 11; end
key.subject_id = subjectId;
key.min_freq = 2;
key.max_freq = 40;
key.low_min = 1;
key.low_max = 5;
key.high_min = 20;
key.high_max = 100;
key = genKey(key, varargin{:});

tet = fetchn(nc.EvokedLfpElectrodes & key, 'electrode_num');
nTet = numel(tet);
[start, Fs] = fetch1(nc.EvokedLfpProfile & key, 'start_time', 'lfp_sampling_rate');

% get evoked LFPs
nStim = count(nc.EvokedLfpStims & key);
lfp = fetchn(nc.EvokedLfp & key, 'avg_evoked_lfp', 'ORDER BY electrode_num ASC, stim_start_time ASC');
lfp = reshape([lfp{:}], [numel(lfp{1}), nStim, nTet]);

% pick the tetrodes that are substantially correlated with the average
tmp = reshape(lfp, size(lfp, 1) * size(lfp, 2), size(lfp, 3));
c = corr(tmp, mean(tmp, 2));
ttNdx = c > 0.8;
lfp = lfp(:, :, ttNdx);

% plot the average lfp
figure(subjectId), clf
M = 3; N = 1; K = 1;
subplot(M, N, K); K = K + 1;
x = mean(lfp, 3);
t = start + (0 : size(x, 1) - 1) * 1000 / Fs;
plot(t, bsxfun(@plus, -(0 : size(x, 2) - 1) * 5e-5, x), 'k')
hold on
axis tight
plot([0 0], ylim, '-', 2000 * [1 1], ylim, '-', 'color', 0.5 * ones(1, 3))
axis off
title('Average LFPs')

% plot SVD components
[U, ~, V] = svd(x, 'econ');
subplot(M, N, K); K = K + 1;
ndx = 1 : 4;
plot(t, bsxfun(@plus, -ndx * 0.5, U(:, ndx)))
legend(arrayfun(@(x) sprintf('%d', x), ndx, 'uni', false))
axis tight off
title('SVD components')

% % plot correlation of SVD components with depth of anesthesia
% rat = fetchn(acq.Ephys, nc.LfpPowerRatio & key, 'avg(power_ratio) -> r');
% ndx = 1 : 4;
% b = regress(rat, [V(:, ndx) ones(nStim, 1)]);
% subplot(M, 2, 5);
% plot(rat, V(:, ndx) * b(1 : numel(ndx)), '.k')
% axis square
% axisTight(0.2)
% box off
% xlabel('LFP power ratio')
% ylabel('Weight of LFP component')
% 
% subplot(M, 2, 6);
% stem(ndx, b(1 : numel(ndx)), 'k')
% xlim(ndx([1 end]) + [-1 1] * 0.5)
% box off
% ylabel('Weight of component #')
