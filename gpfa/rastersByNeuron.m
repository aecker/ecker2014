function rastersByNeuron(key, trials, units)
% Visualize GPFA model.
% AE 2013-01-09

window = [-500 3000];

nUnits = count(nc.GpfaUnits & key);
nTrials = count(nc.GratingTrials & key);

spikes = (nc.GpfaUnits * ae.SpikesByTrial * nc.GratingConditions * nc.GratingTrials) & key;
spikes = fetch(spikes, 'spikes_by_trial', 'ORDER BY trial_num, unit_id');
spikes = reshape(spikes, nUnits, nTrials);
spikes = spikes(:, trials);
nTrials = numel(trials);
spikes = reshape(spikes(units(:), :), [size(units) nTrials]);

nUnits = numel(units);
[rows, cols, nTrials] = size(spikes);

% determine density of ticks according to firing rate
N = arrayfun(@(x) numel(x.spikes_by_trial), spikes);
N = mean(N, 3);
density = min(2, 2 ./ N);

% Plot
fig = Figure(2, 'size', [50 * cols, 10 * rows]);
clf
for iCol = 1 : cols
    subplot(1, cols, iCol)
    hold on
    for iRow = 1 : min(rows, nUnits - (iCol - 1) * rows)
        for iTrial = 1 : nTrials
            y = (iCol - 1) * rows + (iRow - 1) + (iTrial - 1) / nTrials;
            t = spikes(iRow, iCol, trials(iTrial)).spikes_by_trial';
            t = t(t > window(1) & t < window(2));
            if ~isempty(t)
                t = repmat(t, 2, 1);
                plot(t, y + [0; density(iRow, iCol) / nTrials], 'k')
            end
        end
    end
    plot(window, (iCol - 1) * rows + repmat(1 : rows - 1, 2, 1), 'k')
    set(gca, 'xlim', window, 'ylim', (iCol - 1) * rows + [0 rows], 'ytick', 0 : rows, 'Box', 'on')
    xlabel('Time [ms]')
    axis ij
    if iCol == 1
        ylabel('Unit')
    end
end
fig.cleanup();
set(get(fig, 'children'), 'box', 'on')
