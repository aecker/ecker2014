% Analysis of spike waveforms across layers
% AE 2013-07-25

folder = '~/lab/projects/anesthesia/figures/layers';
rel = sort.KalmanUnits * nc.Anesthesia * nc.Gratings * ...
    ae.ProjectsStimulation * ae.Projects * acq.EphysStimulationLink * ...
    ae.TetrodeDepths;
restr = 'project_name = "NoiseCorrAnesthesia" and state = "anesthetized" and detect_method_num=4';

[wi, t, d, keys] = fetchn(rel & restr, 'mean_waveform', 'ephys_start_time', 'depth');
t = double(t);


%% normalize and average across channels
fun = @(x) zscore(sqrt(sum([x{:}] .^ 2, 2)) .* sign(sum([x{:}], 2)));
% nrm = @(x) x / max(abs(x)) * (2 * (abs(max(x)) > abs(min(x))) - 1);
% nrm = @(x) x / mean(x(9 : 11));
% fun = @(x) nrm(sqrt(sum([x{:}] .^ 2, 2)) .* sign(sum([x{:}], 2)));
% fun = @(x) zscore(sqrt(sum([x{:}] .^ 2, 2)));
w = cellfun(fun, wi, 'uni', false);
w = [w{:}]';

[U, p] = princomp(w);
n = 5;


mx = @(x) max(sqrt(sum([x{:}] .^ 2, 2)));
h = cellfun(mx, wi);
p = [log(h) p(:, 1 : n - 1)];


%% Fit Gaussian mixture model
k = 10;
rng(100000)
model = gmdistribution.fit(p(:, 1 : n), k);
cl = model.cluster(p(:, 1 : n));
colors = hsv(k);

% plot features
c = flipud(combnk(1 : n, 2));
fig = Figure(1, 'size', [120 150]);
K = size(c, 1);
M = ceil(sqrt(K));
N = ceil(K / M);
bg = 0.2 * ones(1, 3);
for i = 1 : K
    subplot(M, N, i), hold on
    set(gca, 'color', bg)
    for j = 1 : k
        ndx = cl == j;
        plot(p(ndx, c(i, 1)), p(ndx, c(i, 2)), '.', 'color', colors(j, :))
    end
    xlabel(num2str(c(i, 1)))
    ylabel(num2str(c(i, 2)))
    axisTight
end
fig.cleanup();
fig.save(fullfile(folder, 'waveforms_features_scatter.png'));


fig = Figure(2, 'size', [120 150]);
M = ceil(sqrt(k));
N = ceil(k / M);
for i = 1 : k
    subplot(M, N, i), hold on
    set(gca, 'color', bg)
    ndx = cl == i;
    plot(w(ndx, :)', 'color', colors(i, :))
    axisTight
end
fig.cleanup();
fig.save(fullfile(folder, 'waveforms_cluster_avg.png'));


fig = Figure(3, 'size', [150 200]);
s = [];
for i = 1 : n
    s(i) = subplot(n, 1, i); hold on
    set(gca, 'color', bg)
    for j = 1 : k
        ndx = cl == j;
        plot(d(ndx), p(ndx, i), '.', 'color', colors(j, :))
    end
    axisTight
    set(gca, 'xlim', [0 1600], 'xtick', 0 : 400 : 1600)
end
linkaxes(s, 'x')
xlabel('Depth')
fig.cleanup();
fig.save(fullfile(folder, 'waveforms_features_depth.png'));


fig = Figure(4, 'size', [120 150]);
M = ceil(sqrt(k));
N = ceil(k / M);
bins = 100 : 200 : 1600;
for i = 1 : k
    subplot(M, N, i), hold on
    hist(d(cl == i), bins)
    set(gca, 'xlim', [0 1600], 'xtick', 0 : 400 : 1600)
    xlabel('Depth')
end
fig.cleanup();
fig.save(fullfile(folder, 'waveforms_clusters_depth.png'));


%% Extract potential white matter spikes
% based on visual inspection the following seems to be a good axis to
% identify what looks like white matter spikes (assuming first dimension is
% spike height, second is first PC etc.)
P = 4 * p(:, 2) + 10 * p(:, 3);
[~, order] = sort(P);

for i = 1:100, review(sort.KalmanManual & keys(order(i))), end


%%
key = struct;
key.subject_id = 28;
key.electrode_num = 11;
key.detect_method_num = 4;
keys = fetch(sort.KalmanManual & key);
for k = keys', review(sort.KalmanManual & k), end




%% Analysis of sites with inverted spikes vs. rest
% on a subset of manually checked data

load sites

keys9 = fetch(nc.Gratings * ae.ProjectsStimulation * ae.Projects * acq.EphysStimulationLink * sort.KalmanManual ...
    & 'subject_id = 9 AND detect_method_num = 4 AND project_name = "NoiseCorrAnesthesia"', 'ORDER BY electrode_num, ephys_start_time');
keys9 = reshape(keys9, 9, []);
sites9 = sites9(:, unique([keys9.electrode_num]));

keys11 = fetch(nc.Gratings * ae.ProjectsStimulation * ae.Projects * acq.EphysStimulationLink * sort.KalmanManual ...
    & 'subject_id = 11 AND detect_method_num = 4 AND project_name = "NoiseCorrAnesthesia"', 'ORDER BY electrode_num, ephys_start_time');
keys11 = reshape(keys11, 9, []);
sites11 = sites11(:, unique([keys11.electrode_num]));

keysA = [keys9(sites9 == 0); keys11(sites11 == 0)];
keysB = [keys9(sites9 == 1); keys11(sites11 == 1)];
keysC = [keys9(isnan(sites9)); keys11(isnan(sites11))];

%%
key = struct;
key.detect_method_num = 4;
key.sort_method_num = 5;
key.spike_count_start = 30;
key.spike_count_end = 2030;
key = genKey(key, 'subject_id', [9 11]);

excludePairsA = nc.UnitPairMembership * ephys.Spikes & [keysB; keysC];
excludePairsB = nc.UnitPairMembership * ephys.Spikes & [keysA; keysC];
rel = (nc.CleanPairs * nc.NoiseCorrelations * nc.UnitPairMembership & key) - excludePairsA;
ra = fetchn(rel, 'r_noise_avg');
rel = (nc.CleanPairs * nc.NoiseCorrelations * nc.UnitPairMembership & key) - excludePairsB;
rb = fetchn(rel, 'r_noise_avg');




%% Use only tetrodes where WM could be identified

key = struct;
key.detect_method_num = 4;
key.sort_method_num = 5;
key.spike_count_start = 30;
key.spike_count_end = 2030;
key = genKey(key, 'subject_id', [9]);

excludeTT = nc.UnitPairMembership * ephys.Spikes * ae.TetrodeProperties & 'depth_to_wm IS NULL';
rel = ((nc.CleanPairs * nc.NoiseCorrelations & key) - excludeTT) * nc.UnitPairMembership * ephys.Spikes * ae.TetrodeProperties * ae.TetrodeDepths;
[r, d, fr] = fetchn(rel & 'distance = 0', 'r_noise_avg', 'depth - depth_to_wm -> d', 'geom_mean_rate', 'ORDER BY stim_start_time, pair_num');

%
r = r(1 : 2 : end);
fr = fr(1 : 2 : end);
d = reshape(d, 2, []);

ndx = abs(diff(d, [], 1)) < 400;
r = r(ndx);
fr = fr(ndx);
d = mean(d(:, ndx), 1);

bins = -1400 : 100 : 400;
% bins = 700:100:2500;
[m, se, n, binc] = makeBinned(d', r, bins, @mean, @(x) std(x) / sqrt(numel(x)), @numel, 'include');

figure
subplot(2, 1, 1)
bar(binc, n, 1)
subplot(2, 1, 2)
errorbar(binc, m, se, 'k')
