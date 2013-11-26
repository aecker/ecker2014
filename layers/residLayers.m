function residLayers(sameTT, varargin)
% Residual correlations across layers
% AE 2013-07-01

key.subject_id = [9 11 28];
key.transform_num = 5;
key.zscore = false;
key.by_trial = false;
key.sort_method_num = 5;
key.bin_size = 100;
key.max_latent_dim = 1;
key.latent_dim = 1;
key.max_instability = 0.1;
key.kfold_cv = 2;
key.control = 0;
key.max_freq = 10;
key.min_confidence = 0.5;
key.spike_count_end = 2030;
key = genKey(key, varargin{:});

% fig = Figure(1, 'size', [130 200]);
n = numel(key);

for iKey = 1 : n
    
    stimKeys = fetch(nc.Gratings & key(iKey));
    nStim = numel(stimKeys);
    
    m = zeros(nStim, 1);
    se = zeros(nStim, 1);
    
    for iStim = 1 : nStim
        resid = fetchn(nc.GpfaParams * nc.GpfaCovExpl & stimKeys(iStim) & key(iKey), ...
            'corr_resid_test', 'ORDER BY stim_start_time, condition_num');
        resid = cellfun(@offdiag, resid, 'uni', false);
        resid = cat(1, resid{:});
        
        d = fetchn(nc.GpfaParams * nc.GpfaPairs * nc.NoiseCorrelations & stimKeys(iStim) & key(iKey), ...
            'distance', 'ORDER BY stim_start_time, condition_num, index_j, index_i');
        
        if sameTT
            resid = resid(d == 0);
        end
        
        m(iStim) = mean(resid);
        se(iStim) = std(resid) / sqrt(numel(resid));
    end
    
    subplot(3, 1, iKey)
    hold all
    errorbar(m, se)
    
end

% fig.cleanup();

1;
