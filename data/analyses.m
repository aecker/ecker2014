% Plots showing data and tuning curves
% AE 2013-06-12


%% Tuning curves
load ~/lab/projects/anesthesia/figures/viskey.mat
fig = Figure(1, 'size', [250 70]);
i = 1;
for k = fetch(nc.OriTuning & key)'
    rel = nc.OriTuning & k;
    subplot(4, 11, i)
    plot(rel);
    i = i + 1;
end
fig.cleanup()
fig.save('~/lab/projects/anesthesia/figures/data/tuning')
