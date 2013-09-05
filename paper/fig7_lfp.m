function fig7_lfp
% Fig. 7: Low-frequency LFP as a predictor of network state
%
% AE 2013-09-04

% key for analysis parameters
key.project_name = 'NoiseCorrAnesthesia';
key.sort_method_num = 5;
key.min_freq = 0.5;
key.max_freq = 10;
key.spike_count_start = 30;
key.control = 0;
key.bin_size = 100;
key.max_instability = 0.1;
key.min_trials = 20;
key.min_cells = 10;
key.max_contam = 1;
key.transform_num = 5;
key.max_latent_dim = 1;
key.latent_dim = 1;
key.kfold_cv = 1;
key.zscore = false;

states = flipud(unique(fetchn(nc.Anesthesia, 'state')));
fig = Figure(7, 'size', [220 100]);
M = 2; N = 5; k = 1;

for iState = 1 : numel(states)
    subjIds = fetchn(nc.Anesthesia & struct('state', states{iState}), 'subject_id');
    for iSubj = 1 : numel(subjIds);
        subjKey = key;
        subjKey.subject_id = subjIds(iSubj);
        
        % Cross-correlation between lowpass LFP and GPFA network state
        xc = fetchn(nc.AnalysisStims * nc.LfpGpfaCorr * nc.GpfaParams & subjKey, 'xcorr_trial');
        xc = [xc{:}];
        subplot(M, N, k);
        hold on
        T = (size(xc, 1) - 1) / 2;
        t = (-T : T) * key.bin_size;
        plot(t, xc, 'color', 0.5 * ones(1, 3));
        plot(t, mean(xc, 2), 'color', colors(states{iState}), 'linewidth', 2)
        xlabel('Offset (ms)')
        if k == 1
            ylabel('Cross-correlation')
        end
        axis([[-1 1] * min(1000, T * key.bin_size), -0.4, 0.8], 'square')
        
        % LFP weights in GLM
        rel = nc.AnalysisStims * nc.LfpGlmSet * nc.LfpGlm & subjKey;
        w = fetchn(nc.UnitStats, rel, 'AVG(lfp_weight) -> w');
        subplot(M, N, N + k);
        p = prctile(w, [10 90]);
        bins = linspace(p(1) - diff(p), p(2) + diff(p), 25);
        bins = bins - bins(find(bins > 0, 1)) + diff(bins(1 : 2)) / 2;
        h = hist(w, bins);
        h = h / sum(h);
        bar(bins, h, 1, 'FaceColor', colors(states{iState}), 'LineStyle', 'none');
        hold on
        xlabel('Weight')
        if k == 1
            ylabel('Fraction of cells')
        end
        axis tight square
        yl = ylim;
        ylim([0 ceil(yl(2) * 20) / 20 + 0.001])
        plot([0 0], ylim, '--k')
        k = k + 1;
    end
end

fig.cleanup()
file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save(file)
