function visualize(key, trials, gpfa)
% Visualize GPFA model.
% AE 2013-01-09

if nargin < 3
    gpfa = true;
end

window = 30 + [0 2000];  % 30 ms offset hard-coded in nc.GpfaModelSet

nUnits = count(nc.GpfaUnits & key);
nTrials = count(nc.GratingTrials & key);

spikes = (nc.GpfaUnits * ae.SpikesByTrial * nc.GratingConditions * nc.GratingTrials) & key;
spikes = fetch(spikes, 'spikes_by_trial');
spikes = dj.struct.sort(spikes, {'trial_num', 'unit_id'});
spikes = reshape(spikes, nUnits, nTrials);

[model, Y] = fetch1(nc.GpfaModelSet * nc.GpfaModel & key, 'model', 'transformed_data');
model.C = model.C * sign(mean(model.C));
model = GPFA(model);
X = model.estX(Y(:, :, trials(:)));
X = reshape(X, [1, size(X, 2), size(trials)]);
binSize = fetch1(nc.GpfaParams & key, 'bin_size');
tbins = window(1) + binSize / 2 : binSize : window(2);
[~, order] = sort(model.C, 'descend');

% Plot
[rows, cols] = size(trials);
fig = Figure(trials(1), 'size', [40 * cols, 80]);
clf
for iCol = 1 : cols
    subplot(1, cols, iCol)
    hold on
    for iRow = 1 : rows
        for iUnit = 1 : nUnits
            y = (iCol - 1) * rows + (iRow - 1) + (iUnit - 1) / nUnits;
            t = spikes(order(iUnit), trials(iRow, iCol)).spikes_by_trial';
            t = t(t > window(1) & t < window(2));
            if ~isempty(t)
                t = repmat(t, 2, 1);
                plot(t, y + [0; 1 / nUnits / 2], 'k')
            end
        end
        if gpfa
            plot(tbins, (iCol - 1) * rows + 0.2 * -X(:, :, iRow, iCol) + iRow - 0.4, '-r')
        end
    end
    plot(window, (iCol - 1) * rows + repmat(1 : rows - 1, 2, 1), 'k')
    set(gca, 'xlim', [0 2000], 'ylim', (iCol - 1) * rows + [0 rows], 'Box', 'on')
    xlabel('Time [ms]')
    if iCol == 1
        ylabel('Trial')
    end
    axis ij
end
fig.cleanup()

append = {'', '_gpfa'};
file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save([file append{gpfa + 1}])
pause(1)
fig.save([file append{gpfa + 1} '.png'])
