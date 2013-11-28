function corrLayers(varargin)
% Plot noise correlations as a function of layer
% AE 2013-06-28

key = struct;
key.subject_id = [11 28];
key.min_freq = 2;
key.max_freq = 10;
key.min_confidence = 0.5;
key.detect_method_num = 4;
key = genKey(key, varargin{:});

data = fetch(nc.CSD & key, '*');

%%
fig = Figure(1, 'size', [300 60]); clf
subplot(1, 5, 1)
imagesc(data(1).csd_on_t, data(1).csd_depths, 1000 * data(1).csd_on)
xlabel('Time (ms)')
ylabel('Estimated depth from pial surface')
set(gca, 'ytick', -1000 : 200 : 600, 'ylim', [-1000 600])
colorbar
caxis(max(abs(caxis)) * [-1 1])
subplot(1, 5, 2)
imagesc(data(2).csd_on_t, data(2).csd_depths, 1000 * data(2).csd_on)
xlabel('Time (ms)')
set(gca, 'ytick', -1000 : 200 : 600, 'ylim', [-1000 600])
colorbar
caxis(max(abs(caxis)) * [-1 1])



%% Noise correlations as a function of layers
clear rKey
rKey.subject_id = 11;
rKey.spike_count_end = 2030;
rKey.detect_method_num = 4;
% rKey.subject_id = 11;
rel = pro(nc.NoiseCorrelations & rKey, nc.UnitPairMembership * ephys.Spikes * ae.TetrodeDepths * nc.TetrodeDepthAdjust * nc.CSD, ...
    'AVG(depth + depth_adjust) - layer4_depth -> d', '2 * STD(depth + depth_adjust) -> diff', '*');
% rel = pro(nc.NoiseCorrelations & rKey, nc.CleanPairs * nc.UnitPairMembership * ephys.Spikes * ae.TetrodeDepths * nc.TetrodeDepthAdjust * nc.CSD, ...
%     'AVG(depth + depth_adjust) - layer4_depth -> d', '2 * STD(depth + depth_adjust) -> diff', '*');
[d, r, fr] = fetchn(rel & 'diff < 200 AND distance>0', 'd', 'r_noise_avg', 'geom_mean_rate');
    

figure
bins = -1100 : 100 : 700;
[m, se, binc] = makeBinned(d, fr, bins, @mean, @(x) std(x) / sqrt(numel(x)), 'include');
errorbar(binc, m, se, 'k')




%% Distribution of recorded clean+stable neurons compared to distribution of electrodes
dd = fetchn(nc.TetrodeDepthAdjust * ae.TetrodeDepths * nc.CSD & key, 'depth + depth_adjust - layer4_depth -> dd');
figure
subplot(211)
h = histc(d, bins);
bar(binc, h(1 : end - 1), 1)
subplot(212)
h = histc(dd, bins);
bar(binc, h(1 : end - 1), 1)


%% VARIANCE OF LATENT VARIABLE


%% RESIDUAL CORRELATIONS





%% FIRST MONKEY
rKey = struct('spike_count_end', 2030, 'subject_id', 9);
rel = pro(nc.NoiseCorrelations & rKey, nc.CleanPairs * nc.UnitPairMembership * ephys.Spikes * ae.TetrodeDepths, ...
    'AVG(depth) - 700 -> d', '2 * STD(depth) -> diff', '*');
rel = pro(nc.NoiseCorrelations & rKey, nc.UnitPairMembership * ephys.Spikes * ae.TetrodeDepths, ...
    'AVG(depth) - 700 -> d', '2 * STD(depth) -> diff', '*');
[d, r] = fetchn(rel & 'diff < 200', 'd', 'r_noise_avg');


%%
subjects = [9 11 28];
clear key
key.sort_method_num = 5;
key.spike_count_end = 2030;
clean = 'fp + fn < 0.1 AND tac_instability < 0.1';
bins = 0 : 200 : 1600;
for i = 1 : 3
    key.subject_id = subjects(i);
    if subjects(i) > 9
        d = fetchn(ephys.SingleUnit * nc.UnitStats * ae.TetrodeDepths * nc.TetrodeDepthAdjust & key & clean, 'depth + depth_adjust -> d');
    else
        d = fetchn(ephys.SingleUnit * nc.UnitStats * ae.TetrodeDepths & key & clean, 'depth');
    end
    subplot(3, 1, i)
    hist(d, bins)
end
    







%%
fig.cleanup();
file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save(sprintf('%s_%d', file, subjectId))
pause(0.5)
fig.save(sprintf('%s_%d.png', file, subjectId))
