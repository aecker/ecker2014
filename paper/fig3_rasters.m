function fig3_rasters
% Fig. 3: rasters grouped by trial
% AE 2013-01-09

load exampleKeys.mat
rastersByTrial(anKey, reshape(2:21, 10, 2), true);
rastersByTrial(awKey, reshape(1:20, 10, 2), true);



function rastersByTrial(key, trials, gpfa)

if nargin < 3
    gpfa = true;
end

f = 0.2 * gpfa;
s = fetch1(nc.Gratings & key, 'stimulus_time');
b = fetch1(nc.GpfaParams & key, 'bin_size');
gpfaBins = 30 + (b / 2 : b : s);

window = [-300, s + 400];
state = fetch1(nc.Anesthesia & key, 'state');

nUnits = count(nc.GpfaUnits & key);
nTrials = count(nc.GratingTrials & key);

spikes = (nc.GpfaUnits * ae.SpikesByTrial * nc.GratingConditions * nc.GratingTrials * stimulation.StimTrials) & key;
spikes = fetch(spikes, 'spikes_by_trial');
spikes = dj.struct.sort(spikes, {'trial_num', 'unit_id'});
spikes = reshape(spikes, nUnits, nTrials);

[model, Y] = fetch1(nc.GpfaModelSet * nc.GpfaModel & key, 'model', 'transformed_data');
model.C = model.C * sign(mean(model.C));
model = GPFA(model);
X = model.estX(Y(:, :, trials(:)));
X = reshape(X, [1, size(X, 2), size(trials)]);
[~, order] = sort(mean(Y(:, :), 2), 'descend');

[rows, cols] = size(trials);
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

fig = Figure(double(state(2)) + gpfa, 'size', [sz * cols, 80]);
clf
for iCol = 1 : cols
    subplot(1, cols, iCol)
    hold on
    for iRow = 1 : rows
        for iUnit = 1 : nUnits
            y = (iCol - 1) * rows + (iRow - 1) + (1 - f) * (iUnit - 1) / nUnits;
            t = spikes(order(iUnit), trials(iRow, iCol)).spikes_by_trial';
            t = t(t > window(1) & t < window(2));
            if ~isempty(t)
                t = repmat(t, 2, 1);
                plot(t, y + [0; (1 - f) / nUnits / 2], 'k')
            end
        end
        if gpfa
            plot(gpfaBins, (iCol - 1) * rows + f * 0.5 * -X(:, :, iRow, iCol) + iRow - f, 'color', colors(state))
        end
    end
    plot(window, (iCol - 1) * rows + repmat(0 : rows - 1, 2, 1), 'k')
    plot(ts, (iCol - 1) * rows - xs, 'k')
    set(gca, 'xlim', window, 'ylim', (iCol - 1) * rows + [-2 * xa, rows], 'Box', 'on', 'xtick', xt)
    xlabel('Time [ms]')
    if iCol == 1
        ylabel('Trial')
    end
    axis ij
end
fig.cleanup()

append = {'', '_gpfa'};
file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save([file append{gpfa + 1} '_' state])
