function plotCSD(subjectId)
% Plot current source density profiles
% AE 2013-02-13

if ~nargin, subjectId = 11; end
key.subject_id = subjectId;
data = fetch(nc.CSD & key, '*');

figure(1), clf
subplot(1, 2, 1)
imagesc(data.csd_on_t, data.csd_depths, 1000 * data.csd_on)
xlabel('Time (ms)')
ylabel('Depth from layer 4')
set(gca, 'ytick', -1200 : 300 : 600)
colorbar
caxis(max(abs(caxis)) * [-1 1])

subplot(1, 2, 2)
imagesc(data.csd_off_t, data.csd_depths, 1000 * data.csd_off)
xlabel('Time (ms)')
set(gca, 'xtick', 2000 : 100 : 2300, 'ytick', -1200 : 300 : 600)
colorbar
caxis(max(abs(caxis)) * [-1 1])
