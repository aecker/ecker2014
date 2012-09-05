function plotRastersLFP(stimKey, lfpFilterNum, sortMethodNum, conditionNum, blocks, window, rmLine)
% Plot spike rasters and LFP trace
%   plotRasters(stimKey, lfpFilterNum, sortMethodNum, conditionNum, blocks, window, rmLine)
%
%   stimKey         primary key (struct) of the stimulation session to use
%   lfpFilterNum    the lfp_filter_num to use (see ae.LfpFilter)
%   sortMethodNum   the sort_method_num to use (see sort.Methods)
%   conditionNum    the condition_num to use (see nc.GratingConditions)
%   blocks          two-element vector containing the first and last block
%                   of trials
%   window          time window relative to stimulus onset
%   rmLine          remove line noise? 
%                       * non-zero frequency values indicate yes
%                       * absolute value indicates frequency of power line
%                       * positive value: project out line noise
%                       * negative value: use notch filter
%
% AE 2012-03-22

if nargin < 7, rmLine = 0; end

key = stimKey;
key.lfp_filter_num = lfpFilterNum;
key.sort_method_num = sortMethodNum;

nCond = count(nc.GratingConditions(key));
trialList = sprintf('condition_num = %d AND trial_num BETWEEN %d AND %d', ...
    conditionNum, nCond * (blocks(1) - 1), nCond * blocks(2));
trialRel = nc.GratingTrials(key) & trialList & stimulation.StimTrials('valid_trial = true');

rel = trialRel * acq.EphysStimulationLink * sort.Sets(key) * ae.SpikesByTrial;
spikes = fetch(rel, 'spikes_by_trial', 'condition_num');
units = unique([spikes.unit_id]);
trials = unique([spikes.trial_num]);

spikes = dj.struct.sort(spikes, {'trial_num', 'unit_id'});
m = numel(trials);
n = numel(units);
ylbl = 'Trials';

lfp = fetch(trialRel * ae.LfpByTrial(key), '*');
lfp = dj.struct.sort(lfp, {'electrode_num', 'trial_num'});
electrodes = unique([lfp.electrode_num]);
[Fs, pre] = fetch1(ae.LfpByTrialSet(key), 'lfp_sampling_rate', 'pre_stim_time');
samples = round((window + pre) * Fs / 1000 + 1);
data = arrayfun(@(x) x.lfp_by_trial(samples(1):samples(2)), lfp, 'UniformOutput', false);
data = reshape([data{:}], [diff(samples)+1, numel(trials), numel(electrodes)]);
trialLfp = mean(data, 3);

% get rid of line noise
if rmLine
    if rmLine > 0
        N = size(trialLfp, 1);
        for harmonic = [1 3]
            q = exp(1i * (0 : N - 1)' / Fs * 2 * pi * rmLine * harmonic);
            q = q / norm(q);
            p = q' * trialLfp;
            lineNoise = q * p;
            trialLfp = trialLfp - (lineNoise + conj(lineNoise));
        end
    else
        wo = abs(rmLine) / Fs * 2;
        [b, a] = iirnotch(wo, wo / 20);
        trialLfp = filtfilt(b, a, trialLfp);
    end
end

meanLfp = mean(trialLfp, 2);
trialLfp = bsxfun(@minus, trialLfp, meanLfp);
trialLfp = bsxfun(@rdivide, bsxfun(@minus, trialLfp, min(trialLfp)), max(trialLfp) - min(trialLfp));
tlfp = window(1) + (1:numel(meanLfp)) * 1000 / Fs;

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
