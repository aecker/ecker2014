% Network state model under dynamic stimulus
%   Multiplicative (gain) firing rate modulations with additive Gaussian
%   noise.
%
% AE 2013-11-04

% Parameters
rng(4)
T = 1000;
N = 1000;
sigma = 0.01;
tau = 150;
sr = 10;        % cosine amplitude for firing rate
mr = 11;        % mean rate

fig = Figure(2, 'size', [80 80]);
hold on
ndx = 10 : 2 * T;
k = [10 20 50 100 200 500 1000 2000];
nk = numel(k);
h = zeros(1, 5);

for iter = 1 : 5
    
    % generate latent process with specified temporal autocorrelation
    t = (-T : T)';
    K = exp(-t .^ 2 / tau ^ 2);
    g = 1 + sigma * real(ifft(bsxfun(@times, fft(randn(2 * T + 1, N)), sqrt(abs(fft(K))))));
    
    % generate firing rate
    F = 3.4;
    phi = t * 2 * pi * F / 1000;
    r = sr * cos(phi) + mr;
    x = poissrnd(repmat(bsxfun(@times, r, g), [1 1 2]));
    mu = mean(x, 2);
    
    % cross-correlation analysis using shuffle predictor (true rate function)
    augment = @(x) [x; zeros(size(x))];
    rm = @(x) x(1 : end - 1, :, :);
    xcorr = @(x, y) rm(fftshift(ifft(fft(augment(x)) .* fft(flipud(augment(y))))));
    
    Sc = xcorr(mu(:, :, 1), mu(:, :, 2));
    C = mean(xcorr(x(:, :, 1), x(:, :, 2)), 2) - Sc;
    A = zeros(4 * T + 1, 2);
    for i = 1 : 2
        Sa = xcorr(mu(:, :, i), mu(:, :, i));
        A(:, i) = mean(xcorr(x(:, :, i), x(:, :, i)), 2) - Sa;
    end
    [~, order] = sort(abs(-2 * T : 2 * T));
    Cint = cumsum(C(order));
    Cint = Cint(1 : 2 : end);
    Aint = cumsum(A(order, :));
    Aint = Aint(1 : 2 : end, :);
    
    Cvar = Cint / sqrt(prod(Aint(end, :)));
    Cbair = Cint ./ sqrt(prod(Aint, 2));
    
    % Plot comparison
    h(1) = plot(ndx, Cvar(ndx), 'color', [0 0.5 0]);
    h(2) = plot(ndx, Cbair(ndx), 'color', [1 0.5 0]);
    
    x0 = bsxfun(@minus, x(1 : 2 * T, :, :), mu(1 : 2 * T, :, :));
    c = zeros(1, nk);
    for i = 1 : nk
        y = reshape(x0, [k(i), 2 * T / k(i) * N, 2]);
        ci = corrcoef(permute(sum(y, 1), [2 3 1]));
        c(i) = ci(1, 2);
    end
    h(3) = plot(k, c, '*', 'color', [0 0.4 1]);
    set(gca, 'xscale', 'log')
    drawnow
end

% plot ground truth
Km = toeplitz(sigma ^ 2 * ifftshift(K));
kk = zeros(1, 2 * T);
kk(1) = Km(1);
for i = 2 : 2 * T
    kk(i) = kk(i - 1) + 2 * sum(Km(i, 1 : i)) - Km(i, i);
end
cp = kk ./ (kk + mr * (1 : 2 * T));
h(5) = plot(1 : 2 * T, cp, 'color', [0 0.4 1]);
xlim(ndx([1 end]))

Kc = sigma ^ 2 * (K(T + 1) + 2 * cumsum(K(T + 2 : end)));
Kc(end + (1 : T)) = Kc(end);
VX = zeros(1, 2);
for i = 1 : 2
    tmp = Km .* (mu(:, i) * mu(:, i)') + diag(mu(:, i));
    VX(i) = sum(tmp(:));
end
tmp = Km .* (mu(:, 1) * mu(:, 2)');
CX = sum(tmp(:));
Kc = Kc / Kc(end) * CX / sqrt(prod(VX(:)));
h(4) = plot(ndx, Kc(ndx), 'k');

legend(h, {'Norm. by total var', ...
           'Bair''s method', ...
           'Binned in x ms bins', ...
           'Autocorr of latent', ...
           'Binned analytical'}, 'location', 'southeast')
xlabel('Integration window (ms)')
ylabel('Correlation')
shg
