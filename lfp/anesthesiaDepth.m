function anesthesiaDepth(varargin)
% Depth of anesthesia.
%
% AE 2013-01-30

restrictions = 'sort_method_num = 5 AND ((spike_count_end = 2000 AND subject_id IN (9, 11)) OR (spike_count_end = 500 AND subject_id IN (8, 23)))';
for key = fetch(nc.LfpPowerRatioParams & varargin)'
    figure, hold all
    for monkey = [8 23 9 11]
        [ratio, r] = fetchn(acq.Ephys, nc.LfpPowerRatio * nc.NoiseCorrelations ...
            & restrictions & key & struct('subject_id', monkey), ...
            'avg(power_ratio)->ratio', 'avg(r_noise_avg)->r');
        plot(ratio, r, '.')
        [rho, p] = corr(ratio(:), r(:));
        fprintf('Correlation coefficient [monkey %d]: %.3f (p = %.3f)\n', monkey, rho, p)
    end
    xlabel('log2(LFP power ratio)')
    ylabel('Average noise correlations')
    title(sprintf('[%d %d] / [%d %d]', key.low_min, key.low_max, key.high_min, key.high_max))
    axisTight()
    set(gca, 'box', 'off')
end
