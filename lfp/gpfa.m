function gpfa()
% Correlation between LFP and first GPFA factor.
% AE 2013-02-01

key.project_name = 'NoiseCorrAnesthesia';
key.sort_method_num = 5;
key.min_freq = 0.5;
key.max_freq = 2;
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
fig = Figure(2, 'size', [150 100]);
M = 2; N = 3;

for iState = 1 : numel(states)
    subjIds = fetchn(nc.Anesthesia & struct('state', states{iState}), 'subject_id');
    k = 1;
    for iSubj = 1 : numel(subjIds);
        subjKey = key;
        subjKey.subject_id = subjIds(iSubj);
        xc = fetchn(nc.AnalysisStims * nc.LfpGpfaCorr * nc.GpfaParams & subjKey, 'xcorr_trial');
        xc = [xc{:}];
        subplot(M, N, (iState - 1) * N + k); k = k + 1;
        hold on
        T = (size(xc, 1) - 1) / 2;
        t = (-T : T) * key.bin_size;
        plot(t, xc, 'color', 0.5 * ones(1, 3));
        plot(t, mean(xc, 2), 'color', colors(states{iState}), 'linewidth', 2)
        xlabel('Offset (ms)')
        if iSubj == 1
            ylabel('Cross-correlation')
        end
        axisTight
        xlim([-1 1] * min(1000, T * key.bin_size))
        ylim([-.4 .8])
    end
end

fig.cleanup()
file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save([file '.png'])
