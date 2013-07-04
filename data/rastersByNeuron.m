function rastersByNeuron(key, trials, units)
% Visualize spike rasters by neuron.
% AE 2013-06-13

s = fetch1(nc.Gratings & key, 'stimulus_time');
window = [-300, s + 400];

nUnits = count(ephys.Spikes & key);
nTrials = count(nc.GratingTrials & key);

spikes = (ae.SpikesByTrial * nc.GratingConditions * nc.GratingTrials * stimulation.StimTrials) & key;
spikes = fetch(spikes, 'spikes_by_trial', 'ORDER BY trial_num, unit_id');
spikes = reshape(spikes, nUnits, nTrials);
spikes = spikes(:, trials);
nTrials = numel(trials);
spikes = reshape(spikes(units, :), [numel(units) nTrials]);

[nUnits, nTrials] = size(spikes);

state = fetch1(nc.Anesthesia & key, 'state');
switch state
    case 'awake'
        sz = 25;
        xt = [0 500];
    case 'anesthetized'
        sz = 40;
        xt = [0 1000 2000];
end

ts = linspace(0, s, 100);
xa = 0.15;
xs = 0.7 * xa * sin(ts / 1000 * fetch1(nc.Gratings & key, 'speed') * 2 * pi) + xa;

% Plot
fig = Figure(double(state(2)), 'size', [sz, 6 * nUnits]);
clf
hold on
for iUnit = 1 : nUnits
    for iTrial = 1 : nTrials
        y = (iUnit - 1) + (iTrial - 1) / nTrials;
        t = spikes(iUnit, iTrial).spikes_by_trial';
        t = t(t > window(1) & t < window(2));
        if ~isempty(t)
            t = repmat(t, 2, 1);
            plot(t, y + [0; 1 / nTrials], 'k')
        end
    end
end
if nUnits > 1
    plot(window, repmat(0 : nUnits - 1, 2, 1), 'k')
end
plot(ts, -xs, 'k')
set(gca, 'xlim', window, 'ylim', [-2 * xa, nUnits], 'ytick', 0 : nUnits, 'yticklabel', [0; units(:)], 'xtick', xt)
xlabel('Time (ms)')
axis ij
ylabel('Unit')
fig.cleanup();

file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save([file '_' state])
