function corrByTetrode(resid, varargin)
% Signal and noise correlations grouped by tetrode.
% AE 2013-07-08

key.sort_method_num = 5;
key.spike_count_end = 530;
key.transform_num = 5;
key.zscore = false;
key.by_trial = true;
key.bin_size = 100;
key.max_latent_dim = 1;
key.max_instability = 0.1;
key.kfold_cv = 2;
key.latent_dim = 1;
key = genKey(key, varargin{:});

sameTT = 'distance < 0.1';

colors = [0.2 0.2 0.2; 0 0.7 0; 0.2 0.2 0.2; 0 0.4 1; 1 0.5 0];
states = {'awake', 'anesthetized'};

fig = Figure(1 + key.by_trial, 'size', [90 50]);

for iState = 1 : 2
    subjectIds = fetchn(nc.Anesthesia & struct('state', states{iState}), 'subject_id');
    nSubjects = numel(subjectIds);
    a = zeros(2, nSubjects);
    b = zeros(2, nSubjects);
    hdl = zeros(1, nSubjects);
    c = 2 * (iState - 1);
    for iSubject = 1 : nSubjects
        
        key.subject_id = subjectIds(iSubject);
        
        if iState == 1 || ~ resid
            [r, rs, tt] = fetchn(nc.CleanPairs * nc.NoiseCorrelations * nc.UnitPairMembership * ephys.Spikes & sameTT & key, ...
                'r_noise_avg', 'r_signal', 'electrode_num', 'ORDER BY stim_start_time, pair_num');
            r = r(1 : 2 : end);
            rs = rs(1 : 2 : end);
            tt = tt(1 : 2 : end);
        else
            rel = nc.Anesthesia * nc.GpfaPairs * nc.GpfaParams * nc.GpfaModelSet * nc.UnitPairMembership ...
                * ephys.Spikes * nc.GpfaCovExpl * nc.NoiseCorrelations * nc.NoiseCorrelationConditions;
            [rs, d, tt] = fetchn(rel & key, 'r_signal', 'distance', 'electrode_num', 'ORDER BY stim_start_time, condition_num, index_j, index_i');
            rs = rs(1 : 2 : end);
            d = d(1 : 2 : end);
            tt = tt(1 : 2 : end);
            sameTT = d < 0.1;
            rs = rs(sameTT);
            tt = tt(sameTT);
            
            r = fetchn(nc.Anesthesia * nc.GpfaParams * nc.GpfaModelSet * nc.GpfaCovExpl & key, ...
                'corr_resid_test', 'ORDER BY stim_start_time, condition_num');
            r = cellfun(@offdiag, r, 'uni', false);
            r = cat(1, r{:});
            r = r(sameTT);
        end
        
        utt = unique(tt);
        sem = @(x) std(x) / sqrt(numel(x));
        bins = [utt; Inf];
        [mr, ser] = makeBinned(tt, r, bins, @mean, sem);
        [mrs, sers] = makeBinned(tt, rs, bins, @mean, sem);
        
        subplot(1, 2, iState)
        hold all
        plot((mrs * [1 1] + sers * [-1 1])', (mr * [1 1])', '-', ...
            (mrs * [1 1])', (mr * [1 1] + ser * [-1 1])', '-', ...
            'color', 0.5 * (colors(c + iSubject, :) + ones(1, 3)));
        hdl(iSubject) = plot(mrs, mr, '.', 'color', colors(c + iSubject, :), 'markersize', 8);
        
        a(:, iSubject) = regress(r, [rs ones(size(rs))]);
        b(:, iSubject) = regress(mr, [mrs ones(size(mrs))]);
    end
    xlabel('Signal correlations')
    if iState == 1
        ylabel('Noise correlations')
    end
    axis square
    axisTight
    axis([-0.5 1 -0.2 0.401])
    
    for iSubject = 1 : nSubjects
        plot(xlim, xlim * a(1, iSubject) + a(2, iSubject), '--', ...
            xlim, xlim * b(1, iSubject) + b(2, iSubject), '-', 'color', colors(c + iSubject, :))
    end
    
    legend(hdl, fetchn(acq.Subjects & genKey(struct, 'subject_id', subjectIds), 'SUBSTR(subject_name, 1, 1) -> s'), 'location', 'northwest')
end
fig.cleanup();

byTrial = {'_bins', '_trials'};
file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save([file byTrial{key.by_trial + 1}])
