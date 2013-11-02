% Toy example illustrating recovery of timescale of a common input process
% AE 2013-11-01

rng(1)  % ensure deterministic behavior

% Parameters
T = 500000;
k = 500;
t = (-T : T)';
sigma = [0 0 0.23 0.12];
tau = [0 0 100 1000/3];
f = [0 0 10 3];

auto = @(tau, f) cos(t * 2 * pi * f / 1000) .* exp(-t .^ 2 / tau ^ 2);
indep = @(K) sample(K) + sqrt(1 - K(t == 0)) * randn(2 * T + 1, 1);

% auto-correlation functions
N = numel(sigma);
K = zeros(2 * T + 1, N);
for i = 1 : N
    K(:, i) = sigma(i) ^ 2 * auto(tau(i), f(i));
end
K(t == 0, :) = 1;

% cross-correlation function
Kc = 0.04 ^ 2 * auto(200, 0);

fig = Figure(1, 'size', [200 200]);
x = zeros(2 * T + 1, 4);

for iter = 1 : 10
    
    % Independent neural rate trajectories with specified autocorr
    for i = 1 : N
        x(:, i) = indep(K(:, i));
    end
    
    % Add latent process with specified temporal autocorrelation
    x = bsxfun(@plus, x, sample(Kc));
    
    % Compute cross-correlograms
    N = i;
    xc = xcorr(x, k, 'unbiased');
    xc = reshape(xc, [2 * k + 1, N, N]);

    % integrate over |dt|
    [~, order] = sort(abs(-k : k));
    xcc = cumsum(xc(order, :, :), 1);
    xcc = xcc(1 : 2 : end, :, :);
    
    % normalize by total variance
    a = diag(permute(xcc(end, :, :), [2 3 1]));
    a = permute(sqrt(a * a'), [3 1 2]);
    rc = bsxfun(@rdivide, xcc, a);
    
    % normalize by integral of ACG (Bair's method)
    rcb = zeros(size(xcc));
    for i = 1 : k + 1
        a = diag(permute(xcc(i, :, :), [2 3 1]));
        a = permute(sqrt(a * a'), [3 1 2]);
        rcb(i, :, :) = xcc(i, :, :) ./ a;
    end
    
    % plot integrated cross-correlograms
    for i = 1 : N
        for j = i : N
            subplot(N + 1, N, (i - 1) * N + j)
            hold all
            if i == j
                plot(xcc(:, i, i), 'color', [0 0.4 1])
                axis tight
            else
                plot(rc(:, i, j), 'color', [0 0.5 0])
                plot(rcb(:, i, j), 'color', [1 0.5 0])
                ylim([0 0.6])
            end
        end
    end
    drawnow
end

% overlay true timecourse of latent process
Kc = ifftshift(Kc);
for i = 1 : N
    Ki = ifftshift(K(:, i));
    for j = i : N
        if i == j
            subplot(N + 1, N, i * N + j)
            c = Ki(1 : k) + Kc(1 : k);
            plot(c, 'k')
            axis([0 k min(0, min(c)) c(2)])
            c = Ki(1) + Kc(1) + 2 * cumsum(Ki(2 : k) + Kc(2 : k));
        else
            v = sum(K(:, [i j]), 1) + sum(Kc);
            c = (Kc(1) + 2 * cumsum(Kc(2 : k))) / sqrt(prod(v));
        end
        subplot(N + 1, N, (i - 1) * N + j)
        plot(c, 'k')
        axis([0 k min(0, min(c)) max(ylim)])
        set(gca, 'xtick', 0 : 100 : k)
        if i ~= j
            set(gca, 'xticklabel', [])
        else
            xlabel('Time lag (ms)')
            ylabel('Auto-correlation')
        end
        if i == j - 1
            ylabel('Cross-correlation')
        end
    end
end

fig.cleanup()
file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save(file)
