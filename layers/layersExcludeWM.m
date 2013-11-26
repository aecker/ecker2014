% Analysis of NC as a function of layers excluding potential white matter
% electrodes
%
% AE 2013-07-29


%% Noise correlations as a function of layers
load sites
key = struct;
key.subject_id = 11;
key.spike_count_end = 2030;
key.detect_method_num = 4;
key.sort_method_num = 5;
excludeTT = sprintf(', %d', find(any(sites11)));
excludeTT = sprintf('electrode_num IN (-1%s)', excludeTT);
rel = pro(nc.NoiseCorrelations - (nc.UnitPairMembership * ephys.Spikes & excludeTT) & key, nc.UnitPairMembership * ephys.Spikes * ae.TetrodeDepths * nc.TetrodeDepthAdjust * nc.CSD, ...
    'AVG(depth + depth_adjust) - layer4_depth -> d', '2 * STD(depth + depth_adjust) -> diff', '*');
[d, r, fr] = fetchn(rel & 'diff < 4000', 'd', 'r_noise_avg', 'geom_mean_rate');
 

%% Noise correlations as a function of layers
load sites
key = struct;
key.subject_id = 9;
key.spike_count_end = 2030;
key.detect_method_num = 4;
key.sort_method_num = 5;
excludeTT = sprintf(', %d', find(any(sites9)));
excludeTT = sprintf('electrode_num IN (-1%s)', excludeTT);
rel = (nc.NoiseCorrelations - (nc.UnitPairMembership * ephys.Spikes & excludeTT)) & key;
[r, fr] = fetchn(rel, 'r_noise_avg', 'geom_mean_rate');
 

%%
figure
bins = -1100 : 200 : 700;
[m, se, binc] = makeBinned(d, fr, bins, @mean, @(x) std(x) / sqrt(numel(x)), 'include');
errorbar(binc, m, se, 'k')


%% 
figure
[m, se, binc] = makeBinned(d, r, bins, @mean, @(x) std(x) / sqrt(numel(x)), 'include');
errorbar(binc, m, se, 'k')




%% tetrode depths

d = fetchn(ae.TetrodeDepths * detect.Electrodes & key, 'depth', 'ORDER BY electrode_num, ephys_start_time');
