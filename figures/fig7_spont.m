function fig7_spont
% Fig. 7: GPFA model during spontaneous activity.
%
% AE 2013-10-28

% key for analysis parameters
key.project_name = 'NoiseCorrAnesthesia';
key.sort_method_num = 5;
key.spike_count_start = 30;
key.max_instability = 0.1;
key.min_trials = 20;
key.min_cells = 10;
key.max_contam = 1;
key.bin_size = 100;
key.transform_num = 5;
key.max_latent_dim = 1;
key.latent_dim = 1;
key.kfold_cv = 2;
key.zscore = false;
key.int_bins = 5;

fig = Figure(10, 'size', [150 150]);
M = 3; N = 3;
frbins = -2 : 6;
scax = [-2 6 -0.2 1.0001];
bax = [frbins([1 end]) 0 0.6001];
intbins = [1 2 5 10];
ints = pro(nc.Integers, 'x -> int_bins') & sprintf('int_bins IN (0%s)', sprintf(', %d', intbins));
tsbins = log(25 * 2 .^ (1 : 0.25 : 4));

rel = nc.AnalysisStims * nc.GpfaParams * nc.GpfaSpontSet * nc.GpfaSpontVE * nc.GpfaSpontUnits;
[ve, fr] = fetchn(rel & key, 've_test', 'spont_rate');

% scatter plots: variance explained vs. firing rate
subplot(M, N, 1)
plot(log2(fr), ve, '.k', 'markersize', 3)
axis square
axis(scax)
set(gca, 'xticklabel', 2 .^ get(gca, 'xtick'))
xlabel('Firing raten (spikes/s)')
ylabel('Variance explained')

% binned average VE as a function of firing rate
subplot(M, N, 2)
[m, se, frbinsc] = makeBinned(log2(fr), ve, frbins, @mean, @(x) std(x) / sqrt(numel(x)), 'include');
errorbar(frbinsc, m, se, '.-k')
axis square
axis(bax)
set(gca, 'xticklabel', 2 .^ get(gca, 'xtick'))
xlabel('Firing rate (spikes/s)')

% VE as a function of integration window
subplot(M, N, 3)
hold on
rel = nc.AnalysisStims * nc.GpfaParams * nc.GpfaSpontSet * nc.GpfaSpontVE;
[t, v, se] = fetchn(ints, rel & rmfield(key, 'int_bins'), 'int_bins', 'AVG(ve_test) -> ve', 'STD(ve_test) / SQRT(COUNT(1)) -> se');
t = t * key.bin_size;
errorbar(t, v, se, '.-k')
set(gca, 'xscale', 'log', 'xlim', intbins([1 end]) * key(1).bin_size, ...
    'xtick', intbins * key(1).bin_size, 'xminortick', 'off', 'ylim', [0 0.2])
xlabel('Integration window (ms)')
axis square


% obtain factor loadings
rel = nc.Anesthesia * nc.GpfaParams * nc.GpfaSpontSet * nc.GpfaSpont & key;
[model, Y, train] = fetchn(rel, 'model', 'transformed_data', 'train_set');
Ci = cellfun(@getLoadings, model, Y, train, 'uni', false);
C = cat(1, Ci{:});

% plot distribution of loadings
subplot(M, N, 4);
x = cellfun(@(C) linspace(0, 1, size(C, 1))', Ci, 'uni', false);
x = cat(1, x{:});
plot(x + randn(size(x)) / 50, C, '.k', 'markersize', 1)
hold on
bins = -0.025 : 0.05 : 1.025;
[m, binc] = makeBinned(x, C, bins, @mean, 'include');
plot(binc, m, 'k')
set(gca, 'xlim', [-0.05 1.05], 'xtick', [0.1 0.9], 'xticklabel', {'weakest', 'strongest'}, 'ylim', [-0.2, 1 + eps])
plot(xlim, [0 0], 'k')
ylabel('Weight')
xlabel('Cells sorted by weight')
axis square

% overall distribution of loadings
subplot(M, N, 5);
bins = -0.125 : 0.05 : 1.025;
h = hist(C, bins);
h = h / sum(h);
bar(bins, h, 1, 'facecolor', 'k', 'linestyle', 'none')
hold on
plot([0 0], ylim, '--k')
ylabel('Fraction of cells')
xlabel('Weight')
set(gca, 'xlim', [-0.2 0.65], 'xtick', -0.3 : 0.3 : 0.6)
axis square

% test significance using bootstrap
[m, p, t, ci] = bootstrap(Ci);
fprintf('Weights: %.1f%% positive | Bootstrap CI: [%.1f, %.1f] | p = %.2g | t = %.1f\n', ...
    100 * m, 100 * ci(1), 100 * ci(2), p, t)

% timescale
subplot(M, N, 6)
model = fetchn(nc.AnalysisStims * nc.GpfaParams * nc.GpfaSpontSet * nc.GpfaSpont & key, 'model');
tau = cellfun(@(x) key.bin_size * x.tau, model);
hold on
[h, binc] = makeBinned(log(tau), ones(size(tau)), tsbins, @numel, 'include');
h = h / sum(h);
bar(binc, h, 1, 'FaceColor', 'k', 'LineStyle', 'none');
m = median(tau);
yl = 0.3;
plot(log(m), yl, '.k')
text(log(m), yl, sprintf('   %.1f', m))
set(gca, 'xtick', tsbins(1 : 4 : end), 'box', 'off', 'xlim', tsbins([1 end]), 'ylim', [0, yl + eps])
set(gca, 'xticklabel', exp(get(gca, 'xtick')))
xlabel('Timescale (SD in ms)')
ylabel('Fraction of sites')
axis square

% calculate cutoff frequency for Gaussian kernel
Fs = 10;
d = 10;
t = -d : (1 / Fs) : d;
auto = exp(-t .^ 2 / median(tau / 1000) ^ 2 / 2);  % auto-correlation
auto = auto / sum(auto);
P = db(abs(fft(auto)));                            % power spectrum
cutoff = find(P(2 : end) < -40, 1, 'first') / (2 * d);
fprintf('Cutoff frequency: %.2f (at -40 dB)\n', cutoff)


% residual correlations
linestyles = {'.-k', '.--k'};
for p = 0 : 1
    key.latent_dim = p;
    rel = nc.AnalysisStims * nc.GpfaParams * nc.GpfaModelSet * nc.GpfaResidCorr ...
        * nc.NoiseCorrelations * nc.NoiseCorrelationConditions;
    [resid, gmr, rs, d, st] = fetchn(rel & key, ...
        'resid_corr_test', 'geom_mean_rate_cond', 'r_signal', 'distance', 'stim_start_time');
    linestyle = linestyles{p + 1};
    
    % Firing rate
    bins = -2 : 6;
    subplot(M, N, 7);
    hold on
    [m, se] = binnedMeanAndErrorbars(log2(gmr), resid, st, bins);
    binc = makeBinned([], [], bins);
    errorbar(binc, m, se, linestyle, 'markersize', 5);
    xlabel('Geometric mean rate (spikes/s)')
    ylabel('Average correlation')
    xlim(bins([1 end])) 
    axis square
    set(gca, 'xtick', bins(2 : end - 1), 'xticklabel', 2 .^ bins(2 : end - 1), ...
        'xlim', bins([1 end]), 'ylim', [-0.02 0.25])
    
    % Signal correlation
    bins = -1 : 0.4 : 1;
    subplot(M, N, 8);
    hold on
    [m, se] = binnedMeanAndErrorbars(rs, resid, st, bins);
    binc = makeBinned([], [], bins);
    errorbar(binc, m, se, linestyle, 'markersize', 5);
    xlabel('Signal correlation')
    set(gca, 'xlim', bins([1 end]), 'xtick', -1 : 0.5 : 1, 'ylim', [-0.02 0.12])
    axis square

    % Distance
    bins = -0.5 : 4.5;
    subplot(M, N, 9);
    hold on
    [m, se] = binnedMeanAndErrorbars(d, resid, st, bins);
    binc = makeBinned([], [], bins);
    errorbar(binc, m, se, linestyle, 'markersize', 5);
    xlabel('Distance (mm)')
    axisTight()
    set(gca, 'xtick', 0 : 4, 'ylim', [-0.02 0.1])
    axis square
end


fig.cleanup()

file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save(file)



function C = getLoadings(model, Y, ndx)

model = GPFA(model);
model = model.normFactors(Y(:, :, ndx));
C = model.C;
C = C * sign(median(C));
C = sort(C);


function [mi, p, t, ci] = bootstrap(Ci)
% Bootstrap p value for fraction positive weights

K = 1000;
N = numel(Ci);
Cr = cell(1, N);
for i = 1 : N
    C = Ci{i};
    C = bsxfun(@times, sign(randn(size(C, 1), K)), C);
    Cr{i} = bsxfun(@times, C, sign(median(C)));
end
Pr = cat(1, Cr{:}) > 0;
Pi = cat(1, Ci{:}) > 0;
mr = mean(Pr(:));
mi = mean(Pi);
t = abs(mi - mr) / std(mean(Pr, 1));
p = 2 * (1 - tcdf(t, K));
ci = prctile(mean(Pr, 1), [5 95]);


function [m, se] = binnedMeanAndErrorbars(x, y, st, bins)
% Compute binned means and error bars.
%   Since the simultaneously recorded pairs aren't independent we can't
%   just use SEM = SD / sqrt(n), since this would underestimate the true
%   standard error. Instead we compute the binned means for each site and
%   then take the SEM over sites. This is not the theoretically optimal
%   solution since the binned means have different errors (they don't
%   contain the same number of data point) and we don't do any error
%   propagation. However, it's a conservative estimate of the SEM since the
%   more reliable data points are given less weight than they should and we
%   therefore overestimate the overall error.

% compute overall binned means (it's the more reliable estimate than first
% averaging sites)
m = makeBinned(x, y, bins, @mean, 'include');

% compute binned means for each site used for error bars
ust = unique(st);
n = numel(ust);
ym = cell(1, n);
for i = 1 : n
    ndx = st == ust(i);
    ym{i} = makeBinned(x(ndx), y(ndx), bins, @mean, 'include');
end
ym = [ym{:}];
se = nanstd(ym) ./ sqrt(sum(~isnan(ym), 2));


function sigma = nanstd(x)
% Standard deviation ignoring NaNs (to avoid usage of stats toolbox).

n = size(x, 1);
sigma = zeros(n, 1);
for i = 1 : n
    sigma(i) = std(x(i, ~isnan(x(i, :))));
end
