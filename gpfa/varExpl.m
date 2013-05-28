function varExpl(varargin)
% Analyze how much variance is explained by one-factor model.
%
%   Here I compute percent variance explained on the test set for the one-
%   factor GPFA model for each cell as a function of both firing rates and
%   brain state.
%   
% AE 2012-03-04

% key for analysis parameters/subjects etc.
key.transform_num = 5;
key.zscore = false;
key.by_trial = false;
key.sort_method_num = 5;
key.bin_size = 100;
key.max_latent_dim = 1;
key.latent_dim = 1;
key.min_stability = 0.1;
key.kfold_cv = 2;
key = genKey(key, varargin{:});

% Compute variance explained
stateKeys = struct('state', {'awake', 'anesthetized', 'anesthetized'}, ...
                   'spike_count_end', {530 2030 530});
N = numel(stateKeys);
ve = cell(1, N);
fr = cell(1, N);
for i = 1 : N
    rel = nc.Anesthesia * nc.GpfaParams * nc.GpfaModelSet * nc.GpfaVarExpl * nc.UnitStatsConditions;
    rel = rel & key & stateKeys(i);
    [ve{i}, fr{i}] = fetchn(rel, '1 - var_unexpl_test -> v', 'mean_rate_cond');
end

% Plot
switch logical(key(1).by_trial)
    case true
        d = 0.05;
        vebins = -0.5 : d : 1;
        vebinsc = vebins(1 : end - 1) + d / 2;
        frbins = -1 : 7;
        scax = [-1 8 -0.5 1];
        bax = [frbins([1 end]) 0 0.5];
        hax = [vebins([1 end]) 0 0.3];
    case false
        d = 0.05;
        vebins = -0.1 : d : 1;
        vebinsc = vebins(1 : end - 1) + d / 2;
        frbins = -1 : 7;
        scax = [-1 8 -0.3 1];
        bax = [frbins([1 end]) 0 0.2];
        hax = [vebins([1 end]) 0 0.5];
end

fig = Figure(1 + key(1).by_trial, 'size', [95 105]);
lines = {'.-', '.-', '.:'};
for i = 1 : 2

    % scatter plots: variance explained vs. firing rate
    subplot(2, 2, i)
    plot(log2(fr{i}), ve{i}, '.', 'color', colors(stateKeys(i).state), 'markersize', 1)
    axis square
    axis(scax)
    set(gca, 'xticklabel', 2 .^ get(gca, 'xtick'))
    xlabel('Firing rate')
    if i == 1
        ylabel('Variance explained')
    end
    
    % binned average VE as a function of firing rate
    subplot(2, 2, 3)
    hold on
    [m, frbinsc] = makeBinned(log2(fr{i}), ve{i}, frbins, @mean, 'include');
    plot(frbinsc, m, lines{i}, 'color', colors(stateKeys(i).state))
    
    % histogram of variance explained for rate > 8 spikes/s
    subplot(4, 2, 4 + 2 * i)
    h = histc(ve{i}(fr{i} > 8), vebins);
    h = h(1 : end - 1) / sum(h);
    bar(vebinsc, h, 1, 'FaceColor', colors(stateKeys(i).state), 'LineStyle', 'none');
    axis(hax)
    xlim(vebins([1 end]))
    if i == 2
        xlabel('Variance explained')
    end
    ylabel('Fraction')
end

% control: anesthetized data with first 500 ms only
subplot(2, 2, 3)
[m, frbinsc] = makeBinned(log2(fr{3}), ve{3}, frbins, @mean, 'include');
plot(frbinsc, m, lines{3}, 'color', colors(stateKeys(3).state))
axis square
axis(bax)
set(gca, 'xticklabel', 2 .^ get(gca, 'xtick'))
xlabel('Firing rate')
ylabel('Average variance explained')
set(legend({'awake', 'anesthetized', 'an. (500 ms)'}), 'position', [0.14 .42 0.25 0.1])

fig.cleanup()

% save figure
byTrial = {'_bins', '_trials'};
file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save([file byTrial{key(1).by_trial + 1}])
pause(1)
fig.save([file byTrial{key(1).by_trial + 1} '.png'])
