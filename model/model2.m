% Network state model
% AE 2013-10-18

n = 64;                             % number of neurons
phi = (0 : n - 1)' / n * 2 * pi;    % preferred orientations
kappa = 2;                          % tuning sharpness
f0 = 2;                             % mean firing rate
f = kappa * cos(phi);               % tuning curves
dt = 100;                           % time window size (ms)
T = 20;                             % trial length (#windows)
M = 1000;                           % #trials

sigma = 0.088;                      % variance of network state
g = sigma * randn(1, M * T);        % network state (gain)
Y = poissrnd(exp(bsxfun(@plus, f + f0, g)));      % spike counts

R = corrcoef(Y');
r = offdiag(R);

fe = exp(f + f0);
fr = offdiag(sqrt(fe * fe'));

rsig = (toeplitz(fe) * fe / n - mean(fe) ^ 2) / var(fe);
rsig = offdiag(toeplitz(rsig));


%
fig = Figure(1, 'size', [100 100]);

subplot(2, 2, 1)
bins = 0 : 6;
[m, binc] = makeBinned(log2(fr), r, bins, @mean);
plot(binc, m, '.-k')
set(gca, 'xtick', bins, 'xticklabel', 2 .^ bins, 'xlim', bins([1 end]), 'ylim', [0 0.25])
xlabel('Firing rate (spikes/s)')
ylabel('Noise correlation')
axis square

subplot(2, 2, 2)
bins = -1 : 0.25 : 1;
[m, binc] = makeBinned(rsig, r, bins, @mean);
plot(binc, m, '.-k')
set(gca, 'xtick', bins(1 : 2 : end), 'xlim', bins([1 end]), 'ylim', [0 0.12])
xlabel('Signal correlation')
axis square

fig.cleanup();
