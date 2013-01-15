function verifyResidCov()
% Verify that calculation of residual covariance is correct.
%   Here we generate data from a latent-factor model, estimate the
%   parameters and then compute the residual covariance. If everything is
%   done correctly it will be equal to R.
%
% AE 2013-01-15


%% generate some toy data with >1 latent factors
N = 200;
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
model = fit(GPFA, Ytrain, 2);
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
bins = bins(1) - 0.05 * diff(bins) : 0.025 : bins(2) + 0.05 * diff(bins);
ca = [-0.2 2];
subplot(m, n, k); k = k + 1;
imagesc(Q)
caxis(ca)
axis square
colorbar
xlabel('Neuron j')
ylabel('Neuron i')
title('Observed cov')
subplot(m, n, k); k = k + 1;
imagesc(Qres)
caxis(ca)
axis square
colorbar
xlabel('Neuron j')
title('Estimated residual cov')
subplot(m, n, k); k = k + 1;
imagesc(model.R)
caxis(ca)
axis square
colorbar
xlabel('Neuron j')
title('True residual cov')
subplot(m, n, k); k = k + 1;
hist(r, bins)
xlim(bins([1 end]))
xlabel('offdiagonals')
ylabel('# of pairs')
subplot(m, n, k); k = k + 1;
hist(rres, bins)
xlim(bins([1 end]))
xlabel('offdiagonals')
subplot(m, n, k); k = k + 1;
plot(model.C, '.-')
xlabel('Neuron #')
ylabel('Weight (C)')
xlim([0, q + 1])

