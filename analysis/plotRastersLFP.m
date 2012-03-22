function plotRastersLFP(key, condition, blocks)
% Plot spike rasters and LFP trace
%   plotRasters(stimKey, condition, blocks) plots the spike
%   rasters for a stimulation session given by stimKey using all available
%   single units. The condition to plot is selected by the scalar input
%   condition; the input blocks is a two-element vector containing the
%   first and last block of trials to plot.
%
% AE 2012-03-22

nCond = 16;
% window = [2500 3500];
window = [0 2000];

trialList = sprintf('condition_num = %d AND trial_num BETWEEN %d AND %d', ...
    condition, nCond * (blocks(1) - 1), nCond * blocks(2));

rel = (nc.GratingTrials(key) & trialList) * acq.EphysStimulationLink ...
    * sort.Sets('sort_method_num=4') * ae.SpikesByTrial;
spikes = fetch(rel, 'spikes_by_trial', 'condition_num');
units = unique([spikes.unit_id]);
trials = unique([spikes.trial_num]);

spikes = dj.struct.sort(spikes, {'trial_num', 'unit_id'});
m = numel(trials);
n = numel(units);
ylbl = 'Trials';

lfp = fetch((nc.GratingTrials(key) & trialList) * ae.LfpByTrial(key), '*');
lfp = dj.struct.sort(lfp, 'trial_num');
electrodes = unique([lfp.electrode_num]);
[Fs, pre] = fetch1(ae.LfpByTrialSet(key), 'lfp_sampling_rate', 'pre_stim_time');
samples = (window + pre) * Fs / 1000;
data = arrayfun(@(x) x.lfp_by_trial(samples(1):samples(2)), lfp, 'UniformOutput', false);
data = reshape([data{:}], [diff(samples)+1, numel(trials), numel(electrodes)]);
% trialLfp = data(:, :, 1);
trialLfp = mean(data, 3);
meanLfp = mean(trialLfp, 2);
trialLfp = bsxfun(@minus, trialLfp, meanLfp);
trialLfp = bsxfun(@rdivide, bsxfun(@minus, trialLfp, min(trialLfp)), max(trialLfp) - min(trialLfp));
tlfp = window(1) + (1:numel(meanLfp)) * 1000 / Fs;

% figure(condition), clf
cla, hold on
tuple = 1;
for i = 1:m
    for j = 1:n
        y = (i - 0.5) + (j - 1) / n / 2;
        t = spikes(tuple).spikes_by_trial';
        t = t(t > window(1) & t < window(2));
        if ~isempty(t)
            t = repmat(t, 2, 1);
            plot(t, y + [0; 1/n/2], 'k')
        end
        plot(tlfp, i - 1 + 0.5 * trialLfp(:, i), 'k')
        tuple = tuple + 1;
    end
end

plot(window, repmat(1:m-1, 2, 1), 'k', 'linewidth', 1)
set(gca, 'xlim', window, 'ylim', [0 m], 'Box', 'on')
ylabel(ylbl)
xlabel('Time [ms]')
