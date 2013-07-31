function residCorrWM(varargin)
% Residual correlations by layer.
%   For tetrodes where white matter could be robustly identified (subject 9
%   only).
%
% AE 2013-07-30

% key for analysis parameters/subjects etc.
key.subject_id = 9;
key.transform_num = 5;
key.zscore = false;
key.by_trial = false;
key.detect_method_num = 4;
key.sort_method_num = 5;
key.bin_size = 100;
key.max_latent_dim = 1;
key.max_instability = 0.1;
key.kfold_cv = 2;
key.control = 0;
key = genKey(key, varargin{:});
assert(isscalar(key), 'Key must be unique!')

maxDist = 300;

stimKeys = fetch(nc.Gratings & key);
nStim = numel(stimKeys);

fig = Figure(1, 'size', [50 100]);
set(fig, 'DefaultAxesColorOrder', [0 0 0; 1 0 0])
bins = -1400 : 200 : 400;

for p = 0 : 1
    
    d = [];
    r = [];
    
    for iStim = 1 : nStim
        nCond = count(nc.GratingConditions & stimKeys(iStim));
        for iCond = 1 : nCond
        
            curKey = key;
            curKey.stim_start_time = stimKeys(iStim).stim_start_time;
            curKey.condition_num = iCond;
            curKey.latent_dim = p;
            
            resid = fetch1(nc.GpfaParams * nc.GpfaModelSet * nc.GpfaCovExpl & curKey, 'corr_resid_test');
            
            rel = nc.GpfaParams * nc.GpfaUnits * nc.Gratings * ephys.Spikes * ae.TetrodeProperties * ae.TetrodeDepths;
            [depth, wm, x, y] = fetchn(rel & curKey, 'depth', 'depth_to_wm', 'loc_x', 'loc_y', 'ORDER BY unit_id');
            
            ndx = ~isnan(wm);
            depth = depth(ndx) - wm(ndx);
            resid = resid(ndx, ndx);
            x = x(ndx);
            y = y(ndx);
            
            dd = abs(bsxfun(@minus, depth, depth'));
            dist = sqrt(bsxfun(@minus, x, x') .^ 2 + bsxfun(@minus, y, y') .^ 2);
            depth = bsxfun(@plus, depth, depth') / 2;
            
            ndx = ~tril(ones(size(dd))) & dd < maxDist & dist > 0;
            
            r = [r; resid(ndx)]; %#ok
            d = [d; depth(ndx)]; %#ok
            
        end
    end
    
    [m, se, n, binc] = makeBinned(d, r, bins, @mean, @(x) std(x) / sqrt(numel(x)), @numel, 'include');
    subplot(2, 1, 1)
    bar(binc, n, 1, 'FaceColor', 'k')
    set(gca, 'xlim', [-1400 400], 'xtick', -1200 : 400 : 400)
    ylabel('# pairs')
    axis square
    subplot(2, 1, 2)
    hold all
    errorbar(binc, m, se)
    set(gca, 'xlim', [-1400 400], 'xtick', -1200 : 400 : 400)
    xlabel('Depth relative to white matter')
    ylabel('Average correlation')
    axis square
end

legend({'Raw', 'Residual'})

fig.cleanup();
1;
