function fig4_params
% Fig. 4: Model parameters (weights and timescale)
%
% AE 2013-08-29

% key for analysis parameters
keys.project_name = 'NoiseCorrAnesthesia';
keys.sort_method_num = 5;
keys.spike_count_start = 30;
keys.max_instability = 0.1;
keys.min_trials = 20;
keys.min_cells = 10;
keys.max_contam = 1;
keys.bin_size = 100;
keys.transform_num = 5;
keys.max_latent_dim = 1;
keys.latent_dim = 1;
keys.kfold_cv = 1;
keys.zscore = false;
keys.control = 0;
keys.int_bins = 5;
keys = genKey(keys, 'state', flipud(unique(fetchn(nc.Anesthesia, 'state'))));

fig = Figure(5, 'size', [100 140]);
M = 3; N = 2;
rng(1)
tsbins = log(25 * 2 .^ (-0.5 : 0.5 : 6.5));

for i = 1 : numel(keys)

    % obtain factor loadings
    rel = nc.Anesthesia * nc.GpfaParams * nc.GpfaModelSet * nc.GpfaModel & keys(i);
    [model, Y, train] = fetchn(rel, 'model', 'transformed_data', 'train_set');
    Ci = cellfun(@getLoadings, model, Y, train, 'uni', false);
    C = cat(1, Ci{:});
    
    % plot distribution of loadings
    subplot(M, N, i);
    x = cellfun(@(C) linspace(0, 1, size(C, 1))', Ci, 'uni', false);
    x = cat(1, x{:});
    plot(x + randn(size(x)) / 50, C, '.k', 'markersize', 1)
    hold on
    bins = -0.025 : 0.05 : 1.025;
    [m, binc] = makeBinned(x, C, bins, @mean, 'include');
    plot(binc, m, 'color', colors(keys(i).state))
    set(gca, 'xlim', [-0.05 1.05], 'xtick', [0.1 0.9], 'xticklabel', {'weakest', 'strongest'}, 'ylim', [-1 1])
    plot(xlim, [0 0], 'k')
    if i == 1
        ylabel('Weight')
    end
    xlabel('Cells sorted by weight')
    axis square
    
    % overall distribution of loadings
    subplot(M, N, N + i);
    bins = -0.325 : 0.05 : 0.65;
    h = hist(C, bins);
    h = h / sum(h);
    bar(bins, h, 1, 'facecolor', colors(keys(i).state), 'linestyle', 'none')
    hold on
    plot([0 0], ylim, '--k')
    if i == 1
        ylabel('Fraction of cells')
    end
    xlabel('Weight')
    set(gca, 'xlim', [-0.35 0.65], 'xtick', -0.3 : 0.3 : 0.6)
    axis square

    % test significance using bootstrap
    [m, p, t, ci] = bootstrap(Ci);
    fprintf('%s:\n  %.1f%% weights positive | Bootstrap CI: [%.1f, %.1f] | p = %.2g | t = %.1f\n', ...
        keys(i).state, 100 * m, 100 * ci(1), 100 * ci(2), p, t)
    
    % timescale
    subplot(M, N, 2 * N + i)
    model = fetchn(nc.AnalysisStims * nc.GpfaParams * nc.GpfaModelSet * nc.GpfaModel & keys(i), 'model');
    tau = cellfun(@(x) keys(i).bin_size * x.tau, model);
    hold on
    [h, binc] = makeBinned(log(tau), ones(size(tau)), tsbins, @numel, 'include');
    h = h / sum(h);
    bar(binc, h, 1, 'FaceColor', colors(keys(i).state), 'LineStyle', 'none');
    m = median(tau);
    plot(log(m), 0.4, '.k')
    text(log(m), 0.4, sprintf('   %.1f', m))
    set(gca, 'xtick', tsbins(2 : 4 : end), 'box', 'off', 'xlim', tsbins([1 end]), 'ylim', [0 0.4])
    set(gca, 'xticklabel', exp(get(gca, 'xtick')))
    xlabel('Timescale (SD in ms)')
    if i == 1
        ylabel('Fraction of sites')
    end   
    axis square
    
    % calculate cutoff frequency for Gaussian kernel
    Fs = 10;
    d = 10;
    t = -d : (1 / Fs) : d;
    auto = exp(-t .^ 2 / median(tau / 1000) ^ 2 / 2);  % auto-correlation
    auto = auto / sum(auto);
    P = db(abs(fft(auto)));                            % power spectrum
    cutoff = find(P(2 : end) < -40, 1, 'first') / (2 * d);
    fprintf('  Cutoff frequency: %.2f (at -40 dB)\n', cutoff)
end

fig.cleanup();
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
