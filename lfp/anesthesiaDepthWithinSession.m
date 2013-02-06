function anesthesiaDepthWithinSession(firstFive)
% Relation of depth of anesthesia and noise correlations within session.
%   We split each recording session in a number of blocks and compute for
%   each block the depth of anesthesia index (ratio of low to high
%   frequency LFP power) and noise correlations. We then look at the
%   correlation between the deviations of each measure from the session
%   average.
%
% AE 2013-02-06

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
key.num_blocks = 3;

% exclude poorly isolated and unstable cells
excludePairs = nc.UnitPairMembership * ephys.SingleUnit * nc.UnitStats ...
    & 'fp + fn > 0.1 OR stability > 0.1';

% average correlations within sessions first, then do stats over sessions
[r, ratio] = fetchn(nc.LfpPowerRatioCorr, nc.LfpPowerRatioCorrPairs ...
    - excludePairs & key & sessions, 'avg(delta_r_noise) -> r', 'delta_power_ratio');

% plots
figure(1), clf
subplot(1, 2, 1)
plot(ratio, r, '.k')
xlabel('log2(LFP power ratio)')
ylabel('Average \Delta r')
axisTight
set(gca, 'box', 'off', 'ylim', [-0.02 0.025])

subplot(1, 2, 2)
sem = @(x) std(x) / sqrt(numel(x));
bins = -0.35 : 0.1 : 0.35;
[m, se, binc] = makeBinned(ratio, r, bins, @mean, sem, 'include');
errorbar(binc, m, se, '.-k')
xlabel('log2(LFP power ratio)')
axisTight
set(gca, 'box', 'off', 'ylim', [-0.02 0.025])
