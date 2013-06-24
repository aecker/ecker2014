% Plots showing data and tuning curves
% AE 2013-06-12

load ~/lab/projects/anesthesia/figures/viskeys.mat


%% Rasters grouped by neurons -- anesthetized
trials = 1 : 2 : 90;
units = [3 4 6 8 9 11 12 13 14 15 18 24 29 30 33];
rastersByNeuron(anKey, trials, units)


%% Rasters grouped by neurons -- awake
trials = 1 : 45;
units = [3 8 10 11 15 17 18 24 25 27 29];
rastersByNeuron(awKey, trials, units)


%% Tuning curves -- anesthetized
fig = Figure(1, 'size', [180 100]);
i = 1;
for k = fetch(nc.OriTuning & anKey)'
    rel = nc.OriTuning & k;
    subplot(6, 8, i)
    plot(rel, 'color', colors('anesthetized'));
    i = i + 1;
end
fig.cleanup()
fig.save('~/lab/projects/anesthesia/figures/data/tuning_anesthetized')


%% tuning curves -- awake
fig = Figure(2, 'size', [180 65]);
i = 1;
for k = fetch(nc.OriTuning & awKey)'
    rel = nc.OriTuning & k;
    subplot(4, 8, i)
    plot(rel, 'color', colors('awake'));
    i = i + 1;
end
fig.cleanup()
fig.save('~/lab/projects/anesthesia/figures/data/tuning_awake')

