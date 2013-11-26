function plotSpectra
% Plot power spectra by tetrode and monkey
% AE 2013-01-31

for subjectId = [8 23 9 11 28]
    figure(subjectId), clf
    set(subjectId, 'defaultaxescolororder', hsv(9))
    k = 1;
    for tetrode = 1 : 24
        key.electrode_num = tetrode;
        key.subject_id = subjectId;
        [Pxx, f] = fetchn(nc.LfpPowerSpectrum & key, 'power_spectrum', 'frequencies');
        subplot(4, 6, k); k = k + 1;
        hold all
        cellfun(@(x, y) plot(x(x < 150), db(y(x < 150))), f, Pxx)
        axisTight
    end
end

