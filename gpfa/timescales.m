function timescales(varargin)
% Timescale of latent factor.
%   timescales() plots histograms of timescales of the Gaussian processes
%   that model the latent factors.
%
% AE 2013-03-07

% key for analysis parameters/subjects etc.
key.transform_num = 5;
key.zscore = false;
key.sort_method_num = 5;
key.bin_size = 100;
key.max_latent_dim = 3;
key.latent_dim = 1;
key.min_stability = 0.1;
key.kfold_cv = 1;
key.control = false;
key = genKey(key, varargin{:});

stateKeys = struct('state', {'awake', 'anesthetized'});
N = numel(stateKeys);

pmax = key(1).latent_dim;
assert(pmax <= 3, 'pmax must be less than 3!')

bins = log(25 * 2 .^ (-0.5 : 0.5 : 6.5));
binsc = bins(1 : end - 1) + diff(bins(1 : 2)) / 2;
binsi = [0 bins(2 : end - 1) Inf];

yl = [0 0.4];
colors = {[0 0.4 1], 'r', 'r'};

fig = Figure(1 + key(1).latent_dim, 'size', [50 * N, 50 * pmax]);

for iState = 1 : N
    rel = nc.Anesthesia * nc.GpfaParams * nc.GpfaModelSet * nc.GpfaModel & key & stateKeys(iState);;
    model = fetchn(rel, 'model');
    for p = 1 : pmax
        tau = key(1).bin_size * cellfun(@(x) x.tau(p), model);
        subplot(pmax, N, (p - 1) * N + iState)
        hold on
        h = histc(log(tau), binsi);
        h = h(1 : end - 1) / sum(h);
        bar(binsc, h, 1, 'FaceColor', colors{iState}, 'LineStyle', 'none');
        m = median(tau);
        plot(log(m), yl(2), '.k')
        text(log(m), yl(2), sprintf('   %.1f', m))
        set(gca, 'xtick', bins(2 : 4 : end), 'box', 'off', 'xlim', bins([1 end]), 'ylim', yl)
        set(gca, 'xticklabel', exp(get(gca, 'xtick')))
        axis square
        if p == pmax
            xlabel('SD of Gaussian process (ms)')
        end
        if iState == 1
            ylabel('Fraction of sites')
        end
    end
end

fig.cleanup()

file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save(file)
pause(1)
fig.save([file '.png'])
