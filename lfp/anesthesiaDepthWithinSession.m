function anesthesiaDepthWithinSession(firstFive)
% Relation of depth of anesthesia and noise correlations within session.
%   We split each recording session in a number of blocks and compute for
%   each block the depth of anesthesia index (ratio of low to high
%   frequency LFP power), noise correlations, and the variance of the first
%   factor in the GPFA model. We then look at the correlation between the
%   deviations of each measure from the session average.
%
% AE 2013-02-08

if nargin && firstFive
    sessions = [fetch(nc.Gratings & 'subject_id = 9', 5); ...
                fetch(nc.Gratings & 'subject_id = 11', 5)];
else
    sessions = 'true';
end

% parameters used for LFP power ratio
key.low_min = 1;
key.low_max = 5;
key.high_min = 20;
key.high_max = 100;
key.num_blocks = 4;
key.transform_num = 2;
key.gpfa_param_num = 4;

% exclude unstable cells
excludePairs = nc.UnitPairMembership * nc.UnitStats & 'stability > 0.2';

% average correlations within sessions first, then do stats over sessions
[r, ratio, v] = fetchn(nc.LfpPowerRatioCorr * nc.LfpPowerRatioGpfaParams * nc.LfpPowerRatioGpfa & key, ...
    nc.LfpPowerRatioCorrPairs - excludePairs & key & sessions, ...
    'avg(delta_r_noise) -> r', 'delta_power_ratio', 'var_x');

% plots
figure(1), clf
M = 2; N = 2; K = 1;
subplot(M, N, K); K = K + 1;
plot(ratio, r, '.k')
xlabel('log2(LFP power ratio)')
ylabel('Average \Delta r')
axisTight
set(gca, 'box', 'off', 'ylim', [-0.02 0.025])
[rho, p] = corr(ratio, r);
text(-0.4, 0.02, sprintf('r = %.2f\np = %.2g', rho, p))

subplot(M, N, K); K = K + 1;
sem = @(x) std(x) / sqrt(numel(x));
bins = -0.3 : 0.1 : 0.35;
[m, se, binc] = makeBinned(ratio, r, bins, @mean, sem, 'include');
errorbar(binc, m, se, '.-k')
xlabel('log2(LFP power ratio)')
axisTight
set(gca, 'box', 'off', 'ylim', [-0.02 0.025], 'xtick', bins)

subplot(M, N, K); K = K + 1;
plot(ratio, v, '.k')
xlabel('log2(LFP power ratio)')
ylabel('Var[x]')
axisTight
set(gca, 'box', 'off', 'ylim', [0.7 1.3])
[rho, p] = corr(ratio, v);
text(-0.4, 1.25, sprintf('r = %.2f\np = %.2g', rho, p))

subplot(M, N, K)
[m, se, binc] = makeBinned(ratio, v, bins, @mean, sem, 'include');
errorbar(binc, m, se, '.-k')
xlabel('log2(LFP power ratio)')
axisTight
set(gca, 'box', 'off', 'ylim', [0.7 1.3], 'xtick', bins)

