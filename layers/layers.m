function layers(cleanOnly, varargin)

key.subject_id = [11 28 9];
key.sort_method_num = 5;
key.spike_count_end = 2030;
key.max_freq = 10;
key.min_confidence = 0.5;
key = genKey(key, varargin{:});

fig = Figure(1 + cleanOnly, 'size', [130 200]);
clf
M = 4;
N = 3;

if cleanOnly
    clean = 'fp + fn < 0.1 AND tac_instability < 0.1';
    cleanPairs = nc.UnitPairMembership * nc.CleanPairs;
else
    clean = 'true';
    cleanPairs = nc.UnitPairMembership;
end
    
for iMethod = 1 : 2

    if iMethod == 1   % non-adjusted
        tetDepths = ae.TetrodeDepths;
        depth = 'depth -> d';
        bins = 0 : 200 : 1600;
    else
        tetDepths = ae.TetrodeDepths * nc.TetrodeDepthAdjust * nc.CSD;
        depth = 'depth + depth_adjust - layer4_depth -> d';
        bins = -1100 : 200 : 600;
    end
    xl = bins([1 end]);
    
    
    for iKey = 1 : numel(key) + 1 - iMethod

        % firing rates
        subplot(M, N, iMethod)
        hold all
        [d, fr] = fetchn(ephys.SingleUnit * nc.UnitStats * tetDepths & key(iKey) & clean, depth, 'mean_rate');
        [m, se, binc] = makeBinned(d, fr, bins, @mean, @(x) std(x) / sqrt(numel(x)), 'include');
        errorbar(binc, m, se)
        set(gca, 'xlim', xl)
        
        % noise correlations
        [d, r, fr] = fetchn(nc.NoiseCorrelations * ephys.Spikes * cleanPairs * tetDepths & key(iKey), ...
            depth, 'r_noise_avg', 'geom_mean_rate', 'ORDER BY stim_start_time, pair_num');
        d = reshape(d, 2, []);
        r = r(1 : 2 : end);
        fr = fr(1 : 2 : end);
        ndx = diff(d, [], 1) < 200;
        md = mean(d, 1);
        md = md(ndx)';
        r = r(ndx);
        fr = fr(ndx);
        
        subplot(M, N, N + iMethod)
        hold all
        [m, se, binc] = makeBinned(md, r, bins, @mean, @(x) std(x) / sqrt(numel(x)), 'include');
        errorbar(binc, m, se)
        set(gca, 'xlim', xl)
        
        
        % linear regression using layer and firing rate
        X = zeros(numel(md), numel(bins));
        X(:, 1) = double(md <= bins(2));
        for i = 2 : numel(bins) - 2
            X(:, i) = md > bins(i) & md <= bins(i + 1);
        end
        X(:, i + 1) = md > bins(i + 1);
        X(:, i + 2) = log2(fr);
        [b, bint] = regress(r, X);
        
        subplot(M, N, 2 * N + iMethod)
        hold all
        rm = b(1 : end - 1);
        rml = rm - bint(1 : end - 1, 1);
        rmh = rm - bint(1 : end - 1, 1);
        errorbar(binc, rm, rml, rmh)
        set(gca, 'xlim', xl)
    end

end



tetDepths = ae.TetrodeDepths * nc.TetrodeDepthAdjust * nc.CSD;
depth = 'depth + depth_adjust - layer4_depth';
bins = -1100 : 200 : 600;

for iKey = 1 : numel(key) + 1 - iMethod
    % firing rates
    subplot(M, N, 3)
    hold all
    [d, m, se] = fetchn(ephys.SpikeSet & key(iKey), ephys.SingleUnit * nc.UnitStats * tetDepths & key(iKey) & clean, ['AVG(' depth ') -> d'], 'AVG(mean_rate) -> fr', 'STD(mean_rate) / SQRT(COUNT(1)) -> se', 'ORDER BY ephys_start_time');
    errorbar(d, m, se)
    set(gca, 'xlim', xl)
    
    % noise correlations
    subplot(M, N, 6)
    hold all
    [m, se] = fetchn(nc.NoiseCorrelationSet & key(iKey), nc.NoiseCorrelations * cleanPairs, 'AVG(r_noise_avg) -> m', 'STD(r_noise_avg) / SQRT(COUNT(1)) -> se', 'ORDER BY ephys_start_time');
    errorbar(d, m, se)
    set(gca, 'xlim', xl)
    
%     
%     % linear regression using layer and firing rate
%     X = zeros(numel(md), numel(bins));
%     X(:, 1) = double(md <= bins(2));
%     for i = 2 : numel(bins) - 2
%         X(:, i) = md > bins(i) & md <= bins(i + 1);
%     end
%     X(:, i + 1) = md > bins(i + 1);
%     X(:, i + 2) = log2(fr);
%     [b, bint] = regress(r, X);
%     
%     subplot(M, N, 4 + iMethod)
%     hold all
%     rm = b(1 : end - 1);
%     rml = rm - bint(1 : end - 1, 1);
%     rmh = rm - bint(1 : end - 1, 1);
%     errorbar(binc, rm, rml, rmh)
%     set(gca, 'xlim', xl)
    
    
end

fig.cleanup();

1;
