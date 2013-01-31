% LFP data analysis
addpath ~/lab/libraries/matlab/
run ~/lab/projects/acq/alex_setPath.m
run ~/lab/projects/anesthesia/code/setPath.m


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
%
% Issues:
%   * This is a very preliminary analysis. I currently just average across
%     tetrodes and use all cells (irrespective of stability or isolation).
%   * It's based on all data, irrespective of stimulus/fixation or
%     spontaneous. Thus there are different fractions of stimulus/no
%     stimulus, eye movements in the awake data, etc.
%
% last update: 2013-01-30

anesthesiaDepth


%% LFP power spectra
%
% Plot power spectra grouped by monkeys and tetrodes. Very preliminary,
% just a couple of summary plots.
%
% last update: 2013-01-31

plotSpectra
