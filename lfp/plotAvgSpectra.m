function plotAvgSpectra
% Plot average power spectrum for each monkey
% AE 2013-09-05

fig = Figure(1, 'size', [80 80]);
hold all

keys = fetch(acq.Subjects & nc.Anesthesia, '*');
for key = keys'
    [Pxx, f] = fetchn(nc.LfpPowerSpectrum & key & nc.AnalysisStims, 'power_spectrum', 'frequencies');
    P = mean([Pxx{:}], 2);
    plot(f{1}, db(P))
end
legend({keys.subject_name})
fig.cleanup();

