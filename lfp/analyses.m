% LFP data analysis
addpath ~/lab/libraries/matlab/
run ~/lab/projects/acq/alex_setPath.m
run ~/lab/projects/anesthesia/code/setPath.m


%% GLM with LFP as input -- weights
%
% Here I fitted a GLM with the LFP and the PSTH as predictors (like Kelly
% et al. 2010). I used the average LFP across all tetrodes that recorded
% single units.
%
%   * LFP weights for both awake animals are distributed mostly around
%     zero (49% and 55% positive). They are significantly positive for one
%     of the two monkeys.
%   * Under anesthesia, weights are biased strongly away from zero,
%     negative for two monkeys (17% and 29% positive) and positive for the
%     third monkey (96% positive). 
%   * The difference between the first two and the third monkey is how the
%     signal was referenced: in the first two monkeys we used reference
%     tetrodes either in white matter or on the surface of the cortex; in
%     the third monkey we referenced relative to ground.
%   * Weights are also much stronger and the LFP explains much more
%     variance in the third monkey. This is presumably related to the
%     referencing.
%
% last update: 2013-09-03

glm()


%% Correlation between LFP and network state in GPFA model
%
% Compute the correlation between the low-pass filtered LFP and the latent
% variable in the GPFA model. The average value for each trial is
% subtracted from both LFP and network state (i.e. only the temporal
% structure within a trial is correlated).
%
%   * The average correlation is around 0.2 when using an LFP frequency
%     band between 0 and 2-3 Hz.
%   * The best correlation is achieved by the log(x + 0.1) transform and
%     when subtracting the mean on each trial from both LFP and latent
%     factor.
%
% last update: 2013-09-03

gpfa()


%% Correlation between depth of anesthesia and NC
%
% Here we compute the ratio of low to high frequency LFP power as a proxy
% of depth of anesthesia (see e.g. Haider et al. 2013) and correlate it
% with the level of noise correlations.
%
%   * There is no significant correlation between the power ratio and level
%     of correlations across sessions within a monkey.
%   * The monkey with higher power ratio has higher correlations on
%     average. This might as well be by chance. Since the effect is not
%     there within monkeys I don't really buy into it at this stage.
%   * There is am almost perfect correlation for the first five sessions in
%     both monkeys. It's possible that there is something special about the
%     superficial layers.
%
% Issues:
%   * This is a very preliminary analysis. I currently just average across
%     tetrodes and use all cells (irrespective of stability or isolation).
%   * It's based on all data, irrespective of stimulus/fixation or
%     spontaneous. Thus there are different fractions of stimulus/no
%     stimulus, eye movements in the awake data, etc.
%
% last update: 2013-02-01

anesthesiaDepth

% plot only the first five sessions
anesthesiaDepthFirstSessions


%% Correlation between depth of anesthesia and NC within sessions
%
% Here we do the same analysis as above but for different time periods
% within a session. For each block we compute two measures: (1) LFP power
% ratio, (2) noise correlations. We then look at the deviations of each
% from the session average. 
%
%   * The level of noise correlations is positively correlated with the
%     depth of anesthesia index (ratio of low vs. high frequency LFP
%     power).
%   * The variance of the first GPFA factor is also positively correlated
%     with the depth of anesthesia. This effect is in fact stronger than
%     for the average correlations, which could be because it's
%     statistically more efficient way to estimate.
%
% Issues:
%   * The effect isn't too robust against changes in parameter settings, so
%     it's possible that I'm looking at a statistical artifact. Need to
%     check with the third monkey for sure.
%   * The effect is stronger when all stable units are included and not
%     only the well isolated ones. Could be due to an increase in
%     statistical power or an artifact.
%
% last update: 2013-02-08

anesthesiaDepthWithinSession

% only first five sessions of each monkey (superficial layers)
anesthesiaDepthWithinSession(true)


%% LFP power spectra
%
% Plot power spectra grouped by monkeys and tetrodes. Very preliminary,
% just a couple of summary plots.
%
% last update: 2013-01-31

plotSpectra

