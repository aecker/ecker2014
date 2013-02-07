function gpfa()
% Correlation between LFP and first GPFA factor.
% AE 2013-02-01

figure(1), clf
nTrans = count(nc.DataTransforms);
mr = zeros(1, nTrans);
for i = 1 : nTrans
    key = struct('sort_method_num', 5, 'zscore', 1, 'transform_num', i, ...
        'min_freq', 0, 'max_freq', 2);
    r = -fetchn(nc.GpfaParams * nc.LfpGpfaCorr & key, 'corr_trial');
    mr(i) = mean(r);
    if i == 4
        subplot(1, 2, 2)
        bins = -0.075 : 0.05 : 0.625;
        h = hist(r, bins);
        h = h / sum(h);
        bar(bins, h, 1)
        xlabel('Correlation between X and LFP')
        ylabel('Fraction of sites')
        set(gca, 'box', 'off')
        axisTight
    end
end
subplot(1, 2, 1)
bar(1 : nTrans, mr, 0.5)
xlabel('Transform #')
ylabel('Average correlation')
axis([0.25 4.75 0 0.28])
set(gca, 'box', 'off')
