function timescales(transformNum, zscore)
% Timescale of latent factor.
%   timescales(transformNum, zscore) plots a histogram of timescales of the
%   Gaussian process that models the latent factor.
%
% AE 2013-01-09

binSize = 100;
restrictions = {sprintf('subject_id in (9, 11) AND sort_method_num = 5 AND kfold_cv = 2 AND cv_run = 1 AND bin_size = %d AND latent_dim = 1', binSize), ...
                 struct('transform_num', transformNum, 'zscore', zscore)};

rel = nc.GpfaModel & restrictions;
model = fetchn(rel, 'model');
tau = binSize * cellfun(@(x) x.tau, model);

% Plot
figure(40), clf, hold on
bins = log(50 * 2 .^ (0 : 0.5 : 8.5));
h = hist(log(tau), bins);
h = h / sum(h);
bar(bins, h, 1, 'FaceColor', 0.5 * ones(1, 3));
m = median(tau);
plot(log(m), 1.1 * max(h), '.r')
text(log(m), 1.1 * max(h), sprintf('   median: %.1f', m))
xlabel('SD of Gaussian process (ms)')
ylabel('Fraction of sites')
set(gca, 'xtick', bins(1 : 2 : end), 'box', 'off', 'xlim', bins([1 end]), 'tickdir', 'out')
set(gca, 'xticklabel', exp(get(gca, 'xtick')))
