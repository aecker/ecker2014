function anesthesiaDepth(varargin)
% Depth of anesthesia.
%
% AE 2013-01-30

restrictions = 'sort_method_num = 5 AND ((spike_count_end = 2000 AND subject_id IN (9, 11)) OR (spike_count_end = 500 AND subject_id IN (8, 23))';
for splitFreq = fetchn(nc.LfpPowerRatioParams & varargin, 'split_freq')'
    figure(splitFreq), clf, hold all
    for monkey = [8 23 9 11]
        restr = sprintf('subject_id = %d AND split_freq = %d', monkey, splitFreq);
        [ratio, r] = fetchn(acq.Ephys, nc.LfpPowerRatio * nc.NoiseCorrelations & restrictions & restr, ...
            'avg(power_ratio)->ratio', 'avg(r_noise_avg)->r');
        plot(ratio, r, '.')
        [rho, p] = corr(ratio(:), r(:), 'type', 'spearman');
        fprintf('Correlation coefficient [monkey %d]: %.3f (p = %.3f)\n', monkey, rho, p)
    end
    xlabel('log2(LFP power ratio)')
    ylabel('Average noise correlations')
    title(sprintf('Split frequency = %d Hz', splitFreq))
    axisTight()
    set(gca, 'box', 'off')
end
