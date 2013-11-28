function toyModel()

%% generate some toy data with >1 latent factors
N = 2000;
train = 1 : 3 * N / 4;
test = 3 * N / 4 + 1 : N;
T = 20;
qi = 16;
p = 2;
q = qi * p;
C = kron(eye(p), ones(qi, 1));
X = randn(p, T, N);
Y = reshape(C * X(1 : end, :), [q T N]) + randn(q, T, N);
offdiag = @(x) x(~tril(ones(size(x))));

% compute correlations
Ytest = Y(:, :, test);
Q = cov(Ytest(1 : end, :)');
r = offdiag(Q);

% fit one-factor GPFA model and compute  residual correlations
Ytrain = Y(:, :, train);
model = fit(GPFA, Ytrain, 1);
model.C = bsxfun(@times, model.C, sign(mean(model.C, 1)));
Qres = model.residCov(Ytest);
rres = offdiag(Qres);

% compute covariance of residuals. this is not the preferred way of doing
% it since it causes negative correlations where there shouldn't be any.
% I'm not 100% sure but I think it's because in this case we're using a
% point estimate of X rather than also taking into account the uncertainty
% about it. the formula used above is from the update rule of the EM
% algorithm and should be the correct one.

% Yres = model.resid(Ytest);
% Qres = cov(Yres(1 : end, :)');
% rres = offdiag(Qres);


%% plot results
figure(1), clf
k = 1;
m = 2;
n = 3;
bins = [min(min(r), min(rres)), max(max(r), max(rres))];
bins = bins(1) - 0.05 * diff(bins) : 0.01 : bins(2) + 0.05 * diff(bins);
ca = [-0.2 2];
subplot(m, n, k); k = k + 1;
imagesc(Q)
caxis(ca)
axis square
colorbar
subplot(m, n, k); k = k + 1;
imagesc(Qres)
caxis(ca)
axis square
colorbar
subplot(m, n, k); k = k + 1;
plot(model.C)
subplot(m, n, k); k = k + 1;
hist(r, bins)
xlim(bins([1 end]))
subplot(m, n, k); k = k + 1;
hist(rres, bins)
xlim(bins([1 end]))


%% esimate latent factor
Xtest = X(1, :, test);
Xest = model.estX(Ytest);
regress(-Xest(:), Xtest(:)) % the difference to 1 is equal to the nagtive 
    % correlations we get. this can't be coincidence... check normalization
    % constraints for X. Maybe there is some normalization issue
    % somewhere...

