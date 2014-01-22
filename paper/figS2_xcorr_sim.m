function figS2_xcorr_sim
% Fig. S2: Network state fluctuations under dynamic stimulus
%
% AE 2013-12-02

% Parameters
rng(6724)
T = 2^11;                           % number of time bins
N = 2^13;                           % number of trials
M = 8;                              % number of neurons
sigma = 0.15 * [1 2 4];             % SD of common gain
tau = 200;                          % timescale of common gain
ampl = 1;                           % amplitude of stimulus modulations
mr = -4;                            % mean rate
f = @(x) exp(x) ./ (1 + exp(x));    % static non-linearity
theta = (0 : M) / M * 2 * pi;       % preferred phases
F = 3.4;                            % stimulus frequency

% cross correlation vectorized (unlike built-in xcorr)
augment = @(x) [x; zeros(size(x))];
rm = @(x) x(1 : end - 1, :, :);
flip = @(x) x(end : -1 : 1, :, :);
xcorr = @(x, y) rm(fftshift(ifft(fft(augment(x)) .* fft(flip(augment(y))))));

fig = Figure(2, 'size', [120 60]);
for sig = sigma
    
    % generate latent process with specified temporal autocorrelation
    t = (-2 * T : 2 * T)';
    K = exp(-1/2 * t .^ 2 / tau ^ 2);
    Kint = cumsum(K(t >= 0));
    g = sig * real(ifft(fft(randn(T * N, 1)) .* sqrt(abs(fft(K, T * N)))));
    g = reshape(g, T, N);
    
    % generate firing rate
    t = (1 : T)';
    phi = t * 2 * pi * F / 1000;
    r = ampl * cos(bsxfun(@minus, phi, theta)) + mr;
    r = bsxfun(@plus, r, permute(g, [1 3 2]));
    x = rand(size(r)) < f(r);
    mu = mean(x, 3);
    
    % cross-correlation analysis using shuffle predictor
    C = zeros(2 * T - 1, M + 1);
    A = C;
    for i = 1 : M + 1
        Sc = xcorr(mu(:, i), mu(:, 1));
        C(:, i) = mean(xcorr(x(:, i, :), x(:, 1, :)), 3) - Sc;
        Sc = xcorr(mu(:, i), mu(:, i));
        A(:, i) = mean(xcorr(x(:, i, :), x(:, i, :)), 3) - Sc;
    end
    [~, order] = sort(abs(-T + 1 : T - 1));
    Cint = cumsum(C(order, :), 1);
    Cint = Cint(1 : 2 : end, :);
    Aint = cumsum(A(order, :), 1);
    Aint = Aint(1 : 2 : end, :);
    Cvar = bsxfun(@rdivide, Cint, sqrt(Aint(end, 1) * Aint(end, :)));
    Cbair = Cint ./ sqrt(bsxfun(@times, Aint(:, 1), Aint));
    
    subplot(1, 2, 1)
    hold on
    plot(mean(Cvar(:, 2 : end), 2), 'k')
    plot(mean(Cbair(:, 2 : end), 2), 'r')
    plot(Kint / Kint(end) * mean(Cvar(3 * tau, 2 : end)), ':', 'color', 0.5 * ones(1, 3))
    
    if sig == sigma(3)
        t = -T + 1 : T - 1;
        win = gausswin(tau / 4 + 1);
        win = win / sum(win);
        CC = convn(mean(C(:, 2 : end), 2), win, 'same');
        AA = convn(C(:, end), win, 'same');
        AA(T) = mean(A(T, 2 : end));
        subplot(1, 2, 2)
        hold on
        plot(t, CC, 'color', [1 0.5 0])
        plot(t, AA, 'color', [0 0.5 0])
        legend({'Cross-correlation', 'Auto-correlation'})
        set(gca, 'yscale', 'log', 'ylim', 10 .^ [-3 2], 'xlim', [-1 1] * 3 * tau, 'xtick', (-2 : 2) * 1.5 * tau)
        set(gca, 'yticklabel', get(gca, 'ytick'))
        xlabel('Time lag (ms')
        ylabel('Correlation')
        axis square
    end
end

subplot(1, 2, 1)
axis square
set(gca, 'xscale', 'log', 'xlim', [1 2000], 'xtick', [1 10 100 1000], 'xticklabel', [1 10 100 1000])
xlabel('Integration time (ms)')
ylabel('Cumulative correlation coefficient')
legend({'Normalized by total variance', 'Method from Bair et al. 2001', 'Ground truth'})
fig.cleanup();

file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save(file)
