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


%% firing rate dependence
bins = 10 .^ (-2.5 : 0.25 : 2);
bins(1) = 0;
[count, bin] = histc(fr, bins); %#ok
sz = [numel(bins) - 1, 1];
m = accumarray(bin, r, sz, @mean);
se = accumarray(bin, r, sz, @(x) std(x) / sqrt(numel(x)));

binCenters = log10(bins(2 : end)) - diff(log10(bins(2 : 3))) / 2;
errorbar(binCenters, m, se, '.-')


%% signal correlation dependence
bins = -1 : 0.25 : 1;
bins(end) = 1.001;
[count, bin] = histc(rs, bins); %#ok
sz = [numel(bins) - 1, 1];
m = accumarray(bin, r, sz, @mean);
se = accumarray(bin, r, sz, @(x) std(x) / sqrt(numel(x)));

binCenters = bins(2 : end) - diff(bins(1 : 2)) / 2;
errorbar(binCenters, m, se, '.-')


%% distance dependence
bins = 0 : 0.18 : 0.72;
% bins = 0 : 0.5 : 4;
[count, bin] = histc(d, bins);
sz = [numel(bins) - 1, 1];
m = accumarray(bin, r, sz, @mean);
se = accumarray(bin, r, sz, @(x) std(x) / sqrt(numel(x)));

binCenters = bins(2 : end) - diff(bins(1 : 2)) / 2;
errorbar(binCenters, m, se, '.-')


