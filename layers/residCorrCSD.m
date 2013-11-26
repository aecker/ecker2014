function residCorrCSD(varargin)
% Residual correlations by layer.
%   Using CSD
%
% AE 2013-07-31

% key for analysis parameters/subjects etc.
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

maxDist = 500;

fig = Figure(1, 'size', [150 100]);
set(fig, 'DefaultAxesColorOrder', [0 0 0; 1 0 0])
bins = -2000 : 200 : 400;

subjKeys = fetch(acq.Subjects & (nc.Anesthesia & 'state = "anesthetized"'));
nSubj = numel(subjKeys);
for iSubj = 1 : nSubj
    
    for p = 0 : 1
        
        d = [];
        r = [];
        
        key.subject_id = subjKeys(iSubj).subject_id;
        
        [dtw, x, y, tt] = fetchn(ae.TetrodeProperties & key, 'depth_to_brain + depth_to_wm -> d', 'loc_x', 'loc_y', 'electrode_num');
        b = robustfit([x y], dtw);
        wm = zeros(24, 1);
        wm(tt) = b(1) + [x y] * b(2: 3);
        
        stimKeys = fetch(nc.Gratings & key);
        nStim = numel(stimKeys);
        for iStim = 1 : nStim
            nCond = count(nc.GratingConditions & stimKeys(iStim));
            for iCond = 1 : nCond
                
                curKey = key;
                curKey.stim_start_time = stimKeys(iStim).stim_start_time;
                curKey.condition_num = iCond;
                curKey.latent_dim = p;
                
                resid = fetch1(nc.GpfaParams * nc.GpfaModelSet * nc.GpfaCovExpl & curKey, 'corr_resid_test');
                
                rel = nc.GpfaParams * nc.GpfaUnits * nc.Gratings * ephys.Spikes * ae.TetrodeProperties * ae.TetrodeDepths;
                [depth, x, y, tt] = fetchn(rel & curKey, 'depth + depth_to_brain -> d', 'loc_x', 'loc_y', 'electrode_num', 'ORDER BY unit_id');
                
                depth = depth - wm(tt);
                dd = abs(bsxfun(@minus, depth, depth'));
                dist = sqrt(bsxfun(@minus, x, x') .^ 2 + bsxfun(@minus, y, y') .^ 2);
                depth = bsxfun(@plus, depth, depth') / 2;
                
                ndx = ~tril(ones(size(dd))) & dd < maxDist & dist > 0;
                
                r = [r; resid(ndx)]; %#ok
                d = [d; depth(ndx)]; %#ok
                
            end
        end
        
        [m, se, n, binc] = makeBinned(d, r, bins, @mean, @(x) std(x) / sqrt(numel(x)), @numel, 'include');
        subplot(2, 3, iSubj)
        bar(binc, n, 1, 'FaceColor', 'k')
        set(gca, 'xlim', [-2000 400], 'xtick', -2000 : 1000 : 0)
        ylabel('# pairs')
        axis square
        subplot(2, 3, 3 + iSubj)
        hold all
        errorbar(binc, m, se)
        set(gca, 'xlim', [-2000 400], 'xtick', -2000 : 1000 : 0, 'ylim', [0 0.1])
        grid
        xlabel('Depth relative to white matter')
        ylabel('Average correlation')
        axis square
    end
end

legend({'Raw', 'Residual'})

fig.cleanup();
file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save(file)
pause(0.5)
fig.save([file '.png'])
