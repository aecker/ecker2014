function csd(subjectId, varargin)
% Plot current source density profiles
% AE 2013-02-13

if ~nargin, subjectId = 11; end
key.subject_id = subjectId;
key.min_freq = 2;
key.min_confidence = 0.5;
key = genKey(key, varargin{:});
data = fetch(nc.CSD & key, '*');

fig = Figure(1, 'size', [110 60]); clf
subplot(1, 2, 1)
imagesc(data.csd_on_t, data.csd_depths + data.layer4_depth, 1000 * data.csd_on)
xlabel('Time (ms)')
ylabel('Estimated depth from pial surface')
set(gca, 'ytick', 0 : 400 : 1600, 'ylim', [0 1600])
colorbar
caxis(max(abs(caxis)) * [-1 1])

subplot(1, 2, 2)
imagesc(data.csd_off_t, data.csd_depths + data.layer4_depth, 1000 * data.csd_off)
xlabel('Time (ms)')
set(gca, 'ytick', 0 : 400 : 1600, 'ylim', [0 1600])
colorbar
caxis(max(abs(caxis)) * [-1 1])

% fig.cleanup();
file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save(sprintf('%s_%d', file, subjectId))
