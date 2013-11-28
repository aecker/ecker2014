% Toy example illustrating recovery of timescale of a common input process
% AE 2013-11-01


%% Parameters

T = 100000;
t = (-T : T)';
K = @(sigma, tau, f) sigma ^ 2 * cos(t * 2 * pi * f / 1000) .* exp(-t .^ 2 / tau ^ 2);


%% Latent process with specified temporal autocorrelation
common.sigma = 0.05;
common.tau = 200;
common.f = 0;
common.K = K(common.sigma, common.tau, common.f);
common.x = sample(common.K);


%% Independent neural rate trajectories with specified autocorr
rng(1)
N = 32;

i = 1;
neurons(i).sigma = 0.22;
neurons(i).tau = 100;
neurons(i).f = 10;
neurons(i).K = K(neurons(i).sigma, neurons(i).tau, neurons(i).f);
neurons(i).K(t == 0) = 1;
neurons(i).x = sample(neurons(i).K);

i = i + 1;
neurons(i).sigma = 0.16;
neurons(i).tau = 200;
neurons(i).f = 5;
neurons(i).K = K(neurons(i).sigma, neurons(i).tau, neurons(i).f);
neurons(i).K(t == 0) = 1;
neurons(i).x = sample(neurons(i).K);

i = i + 1;
neurons(i) = common;
neurons(i).K(t == 1) = 1;
neurons(i).x = sample(neurons(i).K);

x = [neurons.x, randn(2 * T + 1, N - numel(neurons))];
x = bsxfun(@plus, x, common.x);
x = x(1 : 2 * T, :);


%%
i = i + 1;
k = 1000;
y = reshape(x, [k, 2*T/k, N]);
y = permute(sum(y, 1), [2 3 1]);

xc = xcorr(x(:, 1 : i), k, 'unbiased');
xc = reshape(xc, [2 * k + 1, i, i]);

[~, order] = sort(abs(-k : k));
xcc = cumsum(xc(order, :, :), 1);
xcc = xcc(1 : 2 : end, :, :);

a = diag(permute(xcc(end, :, :), [2 3 1]));
a = permute(sqrt(a * a'), [3 1 2]);
rc = bsxfun(@rdivide, xcc, a);

rcb = zeros(size(xcc));
for i = 1 : k + 1
    a = diag(permute(xcc(i, :, :), [2 3 1]));
    a = permute(sqrt(a * a'), [3 1 2]);
    rcb(i, :, :) = xcc(i, :, :) ./ a;
end


