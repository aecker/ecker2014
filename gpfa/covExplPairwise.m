function covExplPairwise(varargin)
% Analyze how well the GPFA model approximates the covariance matrix.
%
%   For this analysis we look at the off-diagonals of the difference
%   between observed and predicted (by GPFA) covariance matrix.
%
%   It seems like there are a few large values. This is probably because
%   the Anscombe transformation isn't stabilizing the variances
%   sufficiently since the data is quite overdispersed compared to Poisson
%   even when modelling internal factors. We could probably consider
%   z-scoring the data before fitting the model. However, this may put too
%   much emphasis on low-firing rate cells. This needs to be explored
%   further.
%
% AE 2012-12-11

if ~nargin
    restrictions = {'subject_id in (9, 11)', ...
                    'sort_method_num = 5', ...
                    'transform_num = 2', ...
                    'kfold_cv = 2'};
else
    restrictions = varargin;
end

rel = nc.GpfaCovExplPairs & restrictions;
n = count(rel & 'latent_dim = 0');

pmax = 10;
dtrain = zeros(n, pmax + 1);
dtest = zeros(n, pmax + 1);
for p = 0 : pmax
    [dtrain(:, p + 1), dtest(:, p + 1)] = fetchn(rel & struct('latent_dim', p), ...
        'train_ij - pred_ij -> train', 'test_ij - pred_ij -> test');
end

% plot data
figure(20 + data(1).transform_num), clf

subplot(2, 2, 1)
plot(0 : pmax, sqrt(mean(dtrain .^ 2, 1)), '.-k')
xlim([-1 pmax + 1])
title('RMS difference')
set(legend('Training data'), 'box', 'off')
box off

subplot(2, 2, 2)
plot(0 : pmax, median(abs(dtrain), 1), '.-k')
xlim([-1 pmax + 1])
title('median absolute difference')
box off

subplot(2, 2, 3)
plot(0 : pmax, sqrt(mean(dtest .^ 2, 1)), '.-r')
xlim([-1 pmax + 1])
xlabel('# latent factors')
set(legend('Test data'), 'box', 'off')
box off

subplot(2, 2, 4)
plot(0 : pmax, median(abs(dtest), 1), '.-r')
xlim([-1 pmax + 1])
xlabel('# latent factors')
box off
