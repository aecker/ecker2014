% Network state model under dynamic stimulus
% AE 2013-10-30


%% notes
% with stronger correlations and/or higher rates the integrated CCG seemed
% to decrease past the timescale point


%% Parameters

T = 2000;
N = 10000;
sigma = 0.2;
tau = 200;
h = @(x) exp(x) ./ (1 + exp(x));


%% generate latent process with specified temporal autocorrelation
t = (0 : T)';
dt = t - T / 2 - 1;
K = exp(-dt .^ 2 / tau ^ 2);

a = angle(fft(randn(T + 1, N)));
g = sigma * sqrt(T) * real(ifft(bsxfun(@times, exp(1i * a), sqrt(abs(fft(K))))));


%% generate firing rate
F = 3.4;
f0 = -3;
phi = t * 2 * pi * F / 1000;
f = cos(phi) + f0;
r = h(bsxfun(@plus, f, g));
% mu = mean(r, 2);


%% sample spikes
x = binornd(1, cat(3, r, r));
mu = mean(x, 2);


%% cross-correlation analysis using shuffle predictor (true rate function)
% xcorr = @(x, y) fftshift(ifft(fft(x) .* fft(flipud(y))));
% xcorr = @(x, y) ifft(fft(x, 2 * T + 1) .* fft(flipud(y), 2 * T + 1));
augment = @(x) [x; zeros(size(x))];
rm = @(x) x(1 : end - 1, :, :);
xcorr = @(x, y) rm(fftshift(ifft(fft(augment(x)) .* fft(flipud(augment(y))))));

S = xcorr(mu(:, :, 1), mu(:, :, 2));
C = mean(xcorr(x(:, :, 1), x(:, :, 2)), 2) - S;
A = zeros(2 * T + 1, 2);
for i = 1 : 2
    A(:, i) = mean(xcorr(x(:, :, i), x(:, :, i)), 2) - S;
end
[~, order] = sort(abs(-T : T));
Cint = cumsum(C(order));
Cint = Cint(1 : 2 : end);
Aint = cumsum(A(order, :));
Aint = Aint(1 : 2 : end, :);

Cvar = Cint / sqrt(prod(Aint(end, :)));
Cbair = Cint ./ sqrt(prod(Aint, 2));


%% Plot comparison
clf
Kc = cumsum(K(T / 2 + 1 : end));
Kc = Kc / Kc(end) * Cvar(end);
Kc(end : T + 1) = Kc(end);
ndx = 10 : T;
plot(ndx, Cvar(ndx), 'k', ndx, Cbair(ndx), 'r', ndx, Kc(ndx), 'b')
hold on
set(gca, 'xscale', 'log')

x0 = bsxfun(@minus, x(1 : T, :, :), mu(1 : T, :, :));
k = [10 20 50 100 200 500 1000 2000];
nk = numel(k);
c = zeros(1, nk);
for i = 1 : nk
%     y = reshape(x0, [k(i), T / k(i) * N, 2]);
    y = x0(1 : k(i), :, :);
    ci = corrcoef(permute(sum(y, 1), [2 3 1]));
    c(i) = ci(1, 2);
end
plot(k, c, '*b')
xlim(ndx([1 end]))

legend({'Normalized by total variance', ...
        'Bair''s method', ...
        'Cumulative autocorr of latent', ...
        'Binned in x ms bins'}, 'location', 'southeast')
shg

