% Testing Variance Explained measure
% AE 2013-08-23

seed = 1;
rng(seed);

T = 20;
M = 100;
N = 5;
K = 100;

train = 1 : M / 2;
test = setdiff(1 : M, train);

p = 1;
sigmaN = 1e-3;  % GP innovation noise
tol = 1e-4;     % convergence criterion for fitting

ve = zeros(N, K);

for k = 1 : K
    Y = randn(N, T, M);
    model = GPFA('SigmaN', sigmaN, 'Tolerance', tol, 'Seed', seed);
    model = model.fit(Y(:, :, train), p, 'hist');
    ve(:, k) = model.varExpl(Y(:, :, test));
    disp(k)
end

