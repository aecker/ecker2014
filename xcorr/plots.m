[c, cb] = fetchn(nc.CrossCorr * nc.Anesthesia * nc.CleanPairs & 'state="anesthetized" and spike_count_end=2030 and max_contam=1', 'r_ccg', 'r_ccg_bair');
c = [c{:}];
cb = [cb{:}];
ndx = ~any(isnan(cb) | imag(cb) | isnan(c), 1);
C = mean(c(:, ndx), 2);
Cb = mean(cb(:, ndx), 2);
figure
plot(cb, 'r')
hold on
plot(c, 'k')
set(gca, 'xscale', 'log')
