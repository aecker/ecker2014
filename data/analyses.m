% Plots showing data and tuning curves
% AE 2013-06-12


load ~/lab/projects/anesthesia/figures/viskey.mat
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

