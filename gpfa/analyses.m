% GPFA data analysis
addpath ~/lab/libraries/matlab/
run ~/lab/projects/acq/alex_setPath.m
run ~/lab/projects/anesthesia/code/setPath.m


%% Covariance explained (matrix norm)
%
% This analysis looks at the norm of the difference between observed
% covariance matrix and that predicted by the GPFA model.
%
% I'm not sure if this analysis is ideal for a number of reasons. Here
% are some thoughts on it.
%
%   * The values are related to the residual variance of the covariances
%   * We're normalizing by the norm of the observed covariance matrix,
%       which is dominated by the diagonal terms.
%   * How much the diagonal terms account for the overall norm will likely
%       depend on the number of cells since their number is linear in the
%       number of cells while the number of off-diagonals scales with the
%       square.
%
% last update: 2012-12-11

covExpl('subject_id IN (9, 11)', 'sort_method_num = 5', 'kfold_cv = 2', 'transform_num = 2')


%% covariance explained (off-diagonals only)
%
% For this analysis we look at the off-diagonals of the difference between
% observed and predicted (by GPFA) covariance/corrcoef matrix as well as
% the residual covariance/corrcoef matrix after accounting for the latent
% factors.
%
% There are several ways of looking at the data:
%   * Normalize (or not) data before fitting model (parameter zscore)
%   * Analyze covariances or correlation coefficients (parameter coeff)
%   * Consider spike counts per bin (100 ms) or per trial (param byTrial)
%
% last update: 2013-01-18

transformNum = 2;
zscore = 1;
coeff = 1;
covExplPairwise(transformNum, zscore, 0, coeff)
covExplPairwise(transformNum, zscore, 1, coeff)


%% Sanity check for residual variance calculation
%
% This function verifies that the way we compute the residual covariance
% produces the expected result by sampling data from a toy model and
% estimating the parameters.
%
% last update: 2013-01-15

verifyResidCov()


%% Compare data transformations
%
% Here we compare the different data transformations w.r.t. to R^2 between
% observed and predicted spike counts for the one-factor GPFA model.
%
%   * The differences between the transforms aren't too big (ca. 6-7%)
%   * Anscombe transform and log(x + 1) perform best on a per-bin basis.
%       log(x + 0.1) performs (marginally) best for per-trial spike counts.
%   * R^2 is larger for higher firing rates. This is particularly strong
%       for the untransformed data. It seems like the model puts most of
%       its weight here on explaining the high-firing-rate cells.
%   * The model does put a bit more weight on the most active cells, which
%       is evident when looking at z-scored data: R^2 is reduced somewhat
%       for the most active cells, although not by too much. R^2 remains
%       larger for the most active cells. Thus, the model isn't _just_
%       putting large weight on the most active cells.
%
% last update: 2013-01-08

byTrial = 1;
analyzeTransforms(byTrial)


%% Timescale of latent factor (for one-factor GPFA model)
%
% Here we look at the timescale of the latent factor. It's modeled as a
% Gaussian process with Gaussian time kernel, so a typical temporal "bump"
% will last for ca. 4x the timescale value.
%
% last update: 2013-01-09

transformNum = 2;
zscore = 1;
timescales(transformNum, zscore)


%% Distribution of factor loadings for first factor
%
% Here we look at the distribution of factor loadings for the one-factor
% GPFA model.
%
%   * Overall most of the loadings are positive (< 10% negative)
%
%   * Minor caveat to keep in mind: since the sign is arbitrary we flip it
%     such that the median is positive (i.e. more cells with positve
%     loadings than with negative). There may be better ways of flipping
%     (using the mean, or the mean of the out product == correlations). The
%     sign flipping makes the loadings positive on average, even if there
%     is no real effect. The last panel shows that this is not an issue
%     since in such a case the means should be distributed around zero,
%     i.e. the peak of the distribution should be at zero and not at a
%     non-zero value.
%
% last update: 2013-01-22

firstFactorStruct(transformNum, zscore)


%% Visualize GPFA model
%
% Plot rasters for all cells and overlay the estimate of the latent factor.
%
% last update: 2013-01-09

load ~/lab/projects/anesthesia/figures/viskey.mat
visualize(key, trials)
visualize(key, trials2)

