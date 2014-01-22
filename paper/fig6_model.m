function fig_model
% Noise correlations under fluctuating network state
%   We model a homogeneous population of neurons with circular Gaussian
%   tuning curves driven by a common network state (gain), which is
%   modulated with a timescale of 200 ms.
%
% AE 2013-11-25

N = 64;                             % number of neurons
phi = (0 : N - 1) / N * 2 * pi;     % preferred orientations
kappa = 2;                          % tuning sharpness
mu = kappa * cos(phi) - 0.5;        % tuning curve (natural rate)
dt = 100;                           % time window size (ms)
T = 100000;                          % # bins
sigma = 0.15;                       % variance of network state
int = 5;                            % # bins to integrate
tau = 200;                          % timescale of latent process

% generate latent process with specified temporal autocorrelation
t = dt * (-T : T)';
K = exp(-1/2 * t .^ 2 / tau ^ 2);
rng(1);     % ensure deterministic result
g = sigma * real(ifft(bsxfun(@times, fft(randn(2 * T + 1, 1)), sqrt(abs(fft(K))))));

% sample spike counts
f = exp(bsxfun(@plus, g, mu));
Y = poissrnd(f);

% noise correlations by integrating several bins
Y = reshape(Y(1 : 2 * T, :), [int, 2 * T / int, N]);
Y = permute(sum(Y, 1), [2 3 1]);
R = corrcoef(Y);
r = offdiag(R);

% signal correlations
f = exp(mu)';
fr = offdiag(sqrt(f * f'));
rsig = (toeplitz(f) * f / N - mean(f) ^ 2) / var(f, 1);
rsig = offdiag(toeplitz(rsig));

% plot
fig = Figure(1, 'size', [95 50]);

subplot(1, 2, 1)
bins = -1 : 6;
[m, binc] = makeBinned(log2(fr * 1000 / dt), r, bins, @mean);
plot(binc, m, '.-k')
set(gca, 'xtick', bins, 'xticklabel', 2 .^ bins, 'xlim', bins([1 end]))
axis square
xlabel('Geometric mean rate (spikes/s)')
ylabel('Average noise correlation')

subplot(1, 2, 2)
bins = -1 : 0.25 : 1;
[m, binc] = makeBinned(rsig, r, bins, @mean);
plot(binc, m, '.-k')
set(gca, 'xtick', bins(1 : 2 : end), 'xlim', bins([1 end]), 'ylim', [0, 0.1])
axis square
xlabel('Signal correlation')

fig.cleanup();
file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save(file)
