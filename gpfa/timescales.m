function timescales(transformNum, zscore, pmax)
% Timescale of latent factor.
%   timescales(transformNum, zscore, pmax) plots histograms of timescales
%   of the Gaussian processes that model the latent factors.
%
% AE 2013-01-28

binSize = 100;
restrictions = {sprintf('subject_id in (9, 11) AND sort_method_num = 5 AND kfold_cv = 2 AND cv_run = 1 AND bin_size = %d AND latent_dim = %d', binSize, pmax), ...
                 struct('transform_num', transformNum, 'zscore', zscore)};

rel = nc.GpfaParams * nc.GpfaModel & restrictions;
model = fetchn(rel, 'model');

% Plot
figure(100 * transformNum + 10 * zscore + pmax), clf
for i = 1 : pmax
    tau = binSize * cellfun(@(x) x.tau(i), model);
    subplot(pmax, 1, i), hold on
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
end
