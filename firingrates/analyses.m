% Dependence of noise correlations on firing rates
% AE 2012-08-06

key = struct('subject_id', {23}, 'sort_method_num', 5, 'spike_count_end', 500);
excludePairs = nc.UnitPairMembership(key) & ((ephys.SingleUnit(key) & 'fp + fn > 0.1') + (nc.UnitStats(key) & 'stability > 0.1'));
% excludePairs = nc.UnitPairMembership(key) & ((ephys.SingleUnit(key) & 'fp + fn > 1'));
[r, fr, d, rs] = fetchn((nc.NoiseCorrelations(key) * nc.PairStats) - excludePairs, 'r_noise_avg', 'geom_mean_rate', 'distance', 'r_signal');

% throw out nans
ndx = ~isnan(r);
r = r(ndx);
fr = fr(ndx);
d = d(ndx);
rs = rs(ndx);


%% plots
bins = 10 .^ (-2.5 : 0.5 : 2.5);
bins(1) = 0;
[count, bin] = histc(fr, bins);
sz = [numel(bins) - 1, 1];
m = accumarray(bin, r, sz, @mean);
se = accumarray(bin, r, sz, @(x) std(x) / sqrt(numel(x)));

binCenters = log10(bins(2 : end)) - diff(log10(bins(2 : 3))) / 2;
errorbar(binCenters, m, se, '.-')
