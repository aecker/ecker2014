function glm()
% GLM with LFP as inputs
% AE 2013-09-03

key.project_name = 'NoiseCorrAnesthesia';
key.sort_method_num = 5;
key.min_freq = 0.5;
key.max_freq = 10;
key.spike_count_start = 30;
key.control = 0;
key.bin_size = 100;
key.kfold_cv = 2;

states = flipud(unique(fetchn(nc.Anesthesia, 'state')));
fig = Figure(1, 'size', [150 100]);
M = 2; N = 3;

for iState = 1 : numel(states)
    subjIds = fetchn(nc.Anesthesia & struct('state', states{iState}), 'subject_id');
    k = 1;
    for iSubj = 1 : numel(subjIds);
        subjKey = key;
        subjKey.subject_id = subjIds(iSubj);
        rel = nc.AnalysisStims * nc.LfpGlmSet * nc.LfpGlm & subjKey;
        w = fetchn(nc.UnitStats, rel, 'AVG(lfp_weight) -> w');
        subplot(M, N, (iState - 1) * N + k); k = k + 1;
        p = prctile(w, [10 90]);
        bins = linspace(p(1) - diff(p), p(2) + diff(p), 25);
        h = hist(w, bins);
        h = h / sum(h);
        bar(bins, h, 1, 'FaceColor', colors(states{iState}), 'LineStyle', 'none');
        hold on
        xlabel('Weight')
        if iSubj == 1
            ylabel('Fraction of cells')
        end
        axis tight
        plot([0 0], ylim, '--k')
        str = sprintf('%.1f%%\n', mean(w > 0) * 100);
        ax = axis;
        text(ax(2), ax(4), str, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top')
    end
end

fig.cleanup()
file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save([file '.png'])
