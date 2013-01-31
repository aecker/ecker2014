function anesthesiaDepthFirstSessions(n)
% Depth of anesthesia for the first five sessions.
%   This function plots the ratio of low to high frequency LFP power vs.
%   noise correlations for the first five experimental sessions in each
%   anesthetized experiment. This corresponds roughly to the first
%   700-1000 mu depth (layers 2/3 and superficial 4) in the cortex.
%
% AE 2013-01-31

if ~nargin, n = 5; end
key.sort_method_num = 5;
key.spike_count_end = 2000;
key.low_min = 1;
key.low_max = 5;
key.high_min = 20;
key.high_max = 100;
monkeys = [9 11];
figure(1), clf, hold all
for monkey = monkeys
    data = fetch(acq.Ephys, nc.LfpPowerRatio * nc.NoiseCorrelations ...
        & key & struct('subject_id', monkey), ...
        'avg(power_ratio)->ratio', 'avg(r_noise_avg)->r');
    data = dj.struct.sort(data, 'ephys_start_time');
    ratio = [data(1 : n).ratio];
    r = [data(1 : n).r];
    plot(ratio, r, '.')
    [rho, p] = corr(ratio(:), r(:));
    fprintf('Correlation coefficient [monkey %d]: %.3f (p = %.3f)\n', monkey, rho, p)
end
xlabel('log2(LFP power ratio)')
ylabel('Average noise correlations')
title(sprintf('[%d %d] / [%d %d]', key.low_min, key.low_max, key.high_min, key.high_max))
axisTight()
set(gca, 'box', 'off')
legend(fetchn(acq.Subjects & struct('subject_id', num2cell(monkeys)), 'subject_name'), 'location', 'northwest')
