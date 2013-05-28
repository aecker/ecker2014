% Analysis of noise correlation structure


%% Overall histogram of Fano factors and correlations
%
% This is just the overall histogram of Fano factors and correlation
% coefficients, pooling over all sites and pairs.
%
% last update: 2013-05-22

histograms()


%% Correlation structure
%
% Here we look at how noise correlations depend on firing rate, signal
% correlations, and distance between cells for both anesthetized and awake
% monkeys.
%
% There are some notable differences between monkeys within both groups. I
% need to look into the details some more. There are very clear
% differences, though, between the anesthetized and the awake groups.
%
% last update: 2013-01-10

corrStructPlots('subjectIds', {{8 23} {9 11 28}})

% Here we adjust the linear model for the marginal dependences on signal
% correlation by the firing rate dependence and the on for distance by
% signal correlations, since those factors aren't entirely independent.
corrStructPlots('subjectIds', {{8 23} {9 11 28}}, 'adjustPred', true)

