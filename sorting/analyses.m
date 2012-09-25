% Percent spikes missed by different sorting algorithms
% (relative to hit rate)
%
% AE 2012-09-24

match = nc.SortAlgoComp('`match` > 0.8');
[fracKal, fracMog] = fetchn(match & ephys.SingleUnit('(fp + fn) < 0.1'), ...
    '(missed_kalman / hits) -> a', '(missed_mog / hits) -> b');
bins = linspace(0, 1, 50);
figure
hold on

h = histc(fracMog(fracMog < 1), bins);
h = cumsum(h) / numel(fracMog);
plot(bins * 100, h, 'k')

h = histc(fracKal(fracKal < 1), bins);
h = cumsum(h) / numel(fracKal);
plot(bins * 100, h, 'r')

xlim([0 50])
grid
xlabel('Percent spikes missed')
ylabel('Cumulative fraction of clusters')
legend({'old (MoG)', 'new (Kalman)'}, 'location', 'southeast')


%% hit rate for all Kalman-identified clusters
keys = fetch(acq.Ephys & nc.SortAlgoComp);
hits = fetchn(sort.KalmanUnits(keys), nc.SortAlgoComp, 'max(hits / num_spikes_kalman) -> hit');
% hits = fetchn(sort.KalmanUnits(keys) & ephys.SingleUnit('snr > 5'), nc.SortAlgoComp, 'max(`match`) -> hit');
% hits = fetchn(sort.KalmanUnits(keys) & ephys.SingleUnit('(fp + fn) < 0.1'), nc.SortAlgoComp, 'max(`match`) -> hit');
% hits = fetchn(sort.KalmanUnits(keys), nc.SortAlgoComp, 'max(`match`) -> hit');
h = histc(hits, bins);
h(1) = h(1) + count(sort.KalmanUnits(keys) - nc.SortAlgoComp);
h = h / sum(h);

figure
subplot(2, 1, 1)
bar(100 * (bins(1 : end - 1) + diff(bins(1 : 2)) / 2), h(1 : end - 1), 1, 'facecolor', 'k')
ylabel('Fraction of clusters')
xlim([0 100])

subplot(2, 1, 2), hold all
plot(bins * 100, cumsum(h))
xlabel('Hit rate (%)')
ylabel('Cumulative fraction of clusters')
axis([0 100 0 1])

