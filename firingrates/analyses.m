% Dependence of noise correlations on firing rates
% AE 2012-08-06

key = struct('subject_id', {9 11}, 'sort_method_num', 5, 'spike_count_end', 500);
excludePairs = nc.UnitPairMembership(key) & ((ephys.SingleUnit(key) & 'fp + fn > 0.1') + (nc.UnitStats(key) & 'stability > 0.1'));
excludePairs = nc.UnitPairMembership(key) & ((ephys.SingleUnit(key) & 'fp + fn > 0.1'));
[fr, r] = fetchn((nc.NoiseCorrelations(key) * nc.PairStats) - excludePairs, 'geom_mean_rate', 'r_noise_avg');


%% plots
bins = 10 .^ (-2.5 : 0.5 : 2.5);
[count, bin] = histc(fr, bins);
sz = [numel(bins) - 1, 1];
m = accumarray(bin, r, sz, @mean);
se = accumarray(bin, r, sz, @(x) std(x) / sqrt(numel(x)));

binCenters = log10(bins(1 : end - 1)) + diff(log10(bins(1 : 2))) / 2;
errorbar(binCenters, m, se, '.-')
