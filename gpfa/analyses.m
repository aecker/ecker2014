% GPFA data analysis
addpath ~/lab/libraries/matlab/
run ~/lab/projects/acq/alex_setPath.m
run ~/lab/projects/anesthesia/code/setPath.m


%% Compare data transformations
%
% Here we compare the different data transformations w.r.t. to percent
% variance explained on the test set for the one-factor GPFA model.
%
%   * The differences between the transforms aren't too big (5% bin-based,
%       10% trial-based)
%   * Normalization by z-score doesn't change anything significantly. If
%       anything it's slightly worse, probably because too much weight is
%       put on the cells with low rates where not much can be explained
%       (see rate dependence below).
%   * Bin-based Anscombe, sqrt, and log(x + 1) perform significantly better
%       than the other two.
%   * Trial-based all except untransformed perform equally well.
%   * Variance explained is larger for higher firing rates but plateaus for
%       rates > 16 spikes/s. This is likely because for low-firing cells
%       firing rate variability doesn't account for much of the variance
%       if spiking is assumed to be Poisson given the rate. One would
%       expect variance explained to keep increasing with increasing rates
%       (which seems to be the case for the untransformed, unnormalized
%       data) but the transformation/normalization counters that.
%
% last update: 2013-03-04

analyzeTransforms('subject_id', [9 11], 'control', false, 'by_trial', false)
analyzeTransforms('subject_id', [9 11], 'control', false, 'by_trial', true)


%% Variance explained
%
% Here we analyze the variance explained (VE) by the model in more detail:
% how does it depend on firing rates and brain state (awake vs.
% anesthetized)?
%
% The measure of VE I use is 1 - variance unexplained, where the latter is
% computed as the residual variance on a separate test set (to avoid
% overfitting and report honest results). This measure can become negative
% if the model doesn't explain any of the variance. In this case the
% residual variance will be larger than the actual variance in the data. In
% some sense this is an advantage over traditional measures of variance
% explained, which are typically always positive even if the model is not
% appropriate.
%
% I decided against using C*C' as a measure of VE, since it is bound to
% overestimate the fraction of variance explained due to overfitting to the
% training set.
%
%   * The model clearly explaines substantially more variance in
%       anesthetized recordings compared with awake recordings.
%   * VE increases with cells' firing rates both for awake and anesthetized
%       data. It seems to plateau for rates > 16 spikes/s.
%   * Using larger counting windows increases VE substantially for
%       anesthesia but not for awake data. I don't have a terribly good
%       explanation for this at the moment. I first thought it was because
%       the latent process has a faster timescale in awake recordings, but
%       that's not the case as the analysis of the timescale below shows.
%
% last update: 2013-03-07

varExpl('by_trial', false)
varExpl('by_trial', true)


%% Timescale of latent factor (for one-factor GPFA model)
%
% Here we look at the timescale of the latent factors. It's modeled as a
% Gaussian process with Gaussian time kernel, so a typical temporal "bump"
% will last for ca. 2x the timescale value.
%
%   * The timescale of the latent process for anesthesia is ca. 250 ms,
%       which corresponds well to that of typical up and down states (also
%       evident in the raster plots in the illustration figure).
%   * Timescale for awake recordings is substantially slower (ca. 700 ms).
%       This corresponds essentially to entire trials since trials are only
%       500 ms long. It shows that in awake recordings there are no common
%       fluctuations present at the 250 ms timescale we see during
%       anesthesia. Correlations probably arise either on a faster
%       timescale (but then aren't common to all cells and can't be
%       explained by this model) or on much slower timescales (such as
%       electrode drift or fatigue etc.), which can't be completely ruled
%       out in any experiment.
%
% last update: 2013-03-07

timescales()


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


%% Distribution of factor loadings for first factor
%
% Here we look at the distribution of factor loadings for the one-factor
% GPFA model.
%
%   * Overall most of the loadings are positive (< 10% negative)
%
%   * Minor caveat to keep in mind: since the sign is arbitrary we flip it
%     such that the median is positive (i.e. more cells with positve
%     loadings than with negative). The sign flipping makes the loadings
%     positive on average, even if there is no real effect. The last panel
%     shows that this is not an issue since in such a case the means should
%     be distributed around zero, i.e. the peak of the distribution should
%     be at zero and not at a non-zero value.
%
% last update: 2013-01-24

transformNum = 2;
zscore = 1;
p = 2;
factorLoadingStruct(transformNum, zscore, p)


%% Structure of factor loadings with respect to cell properties
%
% Here we correlate the factor loadings with single cell properties such as
% mean firing rate and Fano factor.
%
%   * Loadings of first factor correlate positively with both firing rate
%     and Fano factor. The same is true for the second factor but
%     substantially weaker.
%
%   * Loadings of both first and second factor correlate positively with
%     baseline firing rate (high baseline implies high firing rates).
%   * Loadings of first and second factor decrease with increasing ration
%     of amplitude / baseline (probably because a high ratio implies a low
%     baseline).
%   * Loadings of first factor do not depend on tuning width, but for
%     second factor the loadings decrease with increasing tuning sharpness.
%
%   * Potential extensions to this analysis:
%       - Waveform shape (narrow vs. broad spikes)
%
% last update: 2013-01-25

transformNum = 2;
zscore = 1;
p = 2;

% mean firing rate, Fano factor
factorLoadingUnitProps(transformNum, zscore, p)

% tuning properties: baseline, amplitude / baseline, kappa
factorLoadingTuningProps(transformNum, zscore, p)


%% Visualize GPFA model
%
% Plot rasters for all cells and overlay the estimate of the latent factor.
%
% last update: 2013-01-09

load ~/lab/projects/anesthesia/figures/viskey.mat
visualize(key, trials)
visualize(key, trials2)


%% Structure of residual correlations
%
% Here we look at the correlation structure of the residual correlations
% (after accounting for latent factors). We plot dependence of residual
% correlations on firing rates, signal correlations, difference in
% preferred orientation, and distance.
%
%   * Firing rate dependence disappears after first factor is accounted
%     for. In fact the dependence becomes slightly negative, which I don't
%     have a good explanation for yet. For the bin-based analysis the very
%     high firing pairs have somewhat higher correlations again while for
%     the trial-based spike counts this is not true.
%   * Still positive correlation between signal and noise correlations
%     after accounting for first factor. It's just shifted downwards. One
%     can see that the slightly increased correlations for the pairs with
%     negative signal correlations (which arises because of the firing rate
%     dependence: strongly negative signal correlations imply high firing
%     rates) go away when accounting for one latent factor (which also
%     removes the firing rate dependence).
%   * The sharp drop from within to across tetrodes remains almost
%     entirely. Across tetrodes correlations are now 0.01 on average.
%
% last update: 2013-01-24

pmax = 3;
transformNum = 2;
zscore = 1;
coeff = 1;
residCorrStruct(pmax, transformNum, zscore, 0, coeff) % bin-based
residCorrStruct(pmax, transformNum, zscore, 1, coeff) % trial-based

