function suppl_fig_xcorr_sim
% Network state model under dynamic stimulus
%   Multiplicative (gain) firing rate modulations with Poisson-like
%   Gaussian noise (variance = mean).
%
% AE 2013-12-02

% Parameters
rng(6724)
T = 2^11;                   % number of time bins
N = 2^13;                   % number of trials
M = 8;
sigma = 0.001 * [3; 2] * [1 2 4];    % SD of common gain
tau = [200 500];            % timescale of common gain
ampl = 50;                  % amplitude of stimulus modulations
mr = 50;                    % mean rate
theta = (0 : M) / M * 2 * pi;   % preferred phases
F = 3.4;                    % stimulus frequency

% cross correlation vectorized (unlike built-in xcorr)
augment = @(x) [x; zeros(size(x))];
rm = @(x) x(1 : end - 1, :, :);
flip = @(x) x(end : -1 : 1, :, :);
xcorr = @(x, y) rm(fftshift(ifft(fft(augment(x)) .* fft(flip(augment(y))))));

fig = Figure(2, 'size', [120 60]);
for iTau = 1 : numel(tau)
    subplot(1, 2, iTau);
    hold on
    for sig = sigma(iTau, :)
        
        % generate latent process with specified temporal autocorrelation
        t = (-2 * T : 2 * T)';
        K = exp(-1/2 * t .^ 2 / tau(iTau) ^ 2);
        Kint = cumsum(K(t >= 0));
        g = 1 + sig * real(ifft(fft(randn(T * N, 1)) .* sqrt(abs(fft(K, T * N)))));
        g = reshape(g, T, N);
        
        % generate firing rate
        t = (1 : T)';
        phi = t * 2 * pi * F / 1000;
        r = ampl * cos(bsxfun(@minus, phi, theta)) + mr;
        r = bsxfun(@times, r, permute(g, [1 3 2]));
        x = randn(size(r)) .* sqrt(r) + r;
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
        
        plot(mean(Cvar(:, 2 : end), 2), 'k')
        plot(mean(Cbair(:, 2 : end), 2), 'r')
        plot(Kint / Kint(end) * mean(Cvar(3 * tau(iTau), 2 : end)), ':', 'color', 0.5 * ones(1, 3))
    end
    axis square
    set(gca, 'xscale', 'log', 'xlim', [1 2000], 'xtick', [1 10 100 1000], 'xticklabel', [1 10 100 1000])
    xlabel('Integration time (ms)')
    if iTau == 1
        ylabel('Cumulative correlation')
    end
end
legend({'Total variance', 'Bair''s method', 'Autocorrelation of common gain'})
fig.cleanup();

file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save(file)
