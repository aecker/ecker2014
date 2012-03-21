function plotRasters(stimKey, condition, blocks, byNeuron)
% Plot spike rasters
%   plotRasters(stimKey, condition, blocks, byNeuron) plots the spike
%   rasters for a stimulation session given by stimKey using all available
%   single units. The condition to plot is selected by the scalar input
%   condition; the input blocks is a two-element vector containing the
%   first and last block of trials to plot. The last input byNeuron
%   indicates whether the rasters are blocked by neurons or by trials.
%
% AE 2012-03-20

nCond = 16;
trialList = sprintf('condition_num = %d AND trial_num BETWEEN %d AND %d', ...
    condition, nCond * (blocks(1) - 1), nCond * blocks(2));

rel = (nc.GratingTrials(stimKey) & trialList) * acq.EphysStimulationLink ...
    * sort.Sets('sort_method_num=2') * nc.SpikesByTrial;
spikes = fetch(rel, 'spikes_by_trial', 'condition_num');
units = unique([spikes.unit_id]);
trials = unique([spikes.trial_num]);

if byNeuron
    spikes = dj.struct.sort(spikes, {'unit_id', 'trial_num'});
    m = numel(units);
    n = numel(trials);
    ylbl = 'Neurons';
else
    spikes = dj.struct.sort(spikes, {'trial_num', 'unit_id'});
    m = numel(trials);
    n = numel(units);
    ylbl = 'Trials';
end
window = [-250 2350];
% window = [50 2050];

% figure(condition), clf
cla, hold on
tuple = 1;
for i = 1:m
    for j = 1:n
        y = (i - 1) + (j - 1) / n;
        t = spikes(tuple).spikes_by_trial';
        t = t(t > window(1) & t < window(2));
        if ~isempty(t)
            t = repmat(t, 2, 1);
            plot(t, y + [0; 1/n], 'k')
        end
        tuple = tuple + 1;
    end
end

plot(window, repmat(1:m-1, 2, 1), 'k')
set(gca, 'xlim', window, 'ylim', [0 m], 'Box', 'on')
ylabel(ylbl)
xlabel('Time [ms]')
