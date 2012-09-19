function corrStructPlots(varargin)
% Dependence of noise correlations on firing rates
% AE 2012-08-06

args.subjectIds = [23 8 9 11];
args.sortMethodNum = 5;
args.spikeCountEnd = 500;
args.contam = 0.1;
args.stability = 0.1;
args = parseVarArgs(args, varargin{:});

subjectNames = {};
figure
for subjectId = args.subjectIds(:)'
    
    % restrictions
    key = struct('subject_id', subjectId, ...
        'sort_method_num', args.sortMethodNum, ...
        'spike_count_end', args.spikeCountEnd);
    excludePairs = nc.UnitPairMembership(key) & ( ...
        (ephys.SingleUnit(key) & sprintf('fp + fn > %.16f', args.contam)) + ...
        (nc.UnitStats(key) & sprintf('stability > %.16f', args.stability)));
    
    % obtain data
    [r, fr, d, rs] = fetchn((nc.NoiseCorrelations(key) * nc.PairStats) - excludePairs, ...
        'r_noise_avg', 'min_rate', 'distance', 'r_signal');
    
    % throw out nans and non-spiking pairs
    ndx = ~isnan(r) & fr > 0;
    r = r(ndx);
    fr = fr(ndx);
    d = d(ndx);
    rs = rs(ndx);
    
    % firing rate dependence
    bins = 10 .^ (-2.5 : 0.25 : 1.75);
%     bins(1) = 0;
    [count, bin] = histc(fr, bins);
    sz = [numel(bins) - 1, 1];
    m = accumarray(bin, r, sz, @mean);
    m(count(1 : end - 1) < 5) = NaN;
    se = accumarray(bin, r, sz, @(x) std(x) / sqrt(numel(x)));
    
    subplot(2, 2, 1), hold all
    binCenters = 10 .^ (log10(bins(2 : end)) - diff(log10(bins(2 : 3))) / 2);
    errorbar(binCenters, m, se, '.-')
    set(gca, 'xscale', 'log', 'box', 'off', 'xlim', bins([1 end]))
    xlabel('Geometric mean firing rate (spikes/sec)')
    ylabel('Spike count correlation')
    
    % signal correlation dependence
    bins = -1 : 0.5 : 1;
    bins(end) = 1.001;
    [count, bin] = histc(rs, bins);
    sz = [numel(bins) - 1, 1];
    m = accumarray(bin, r, sz, @mean);
    m(count(1 : end - 1) < 5) = NaN;
    se = accumarray(bin, r, sz, @(x) std(x) / sqrt(numel(x)));
    
    subplot(2, 2, 2), hold all
    binCenters = bins(2 : end) - diff(bins(1 : 2)) / 2;
    errorbar(binCenters, m, se, '.-')
    set(gca, 'box', 'off', 'xlim', bins([1 end]))
    xlabel('Signal correlation')
    ylabel('Spike count correlation')
    
    % distance dependence
    switch subjectId
        case 23
            bins = 0 : 0.18 : 4;
        otherwise
            bins = 0 : 0.5 : 4;
    end
    [count, bin] = histc(d, bins);
    sz = [numel(bins) - 1, 1];
    m = accumarray(bin, r, sz, @mean);
    m(count(1 : end - 1) < 5) = NaN;
    se = accumarray(bin, r, sz, @(x) std(x) / sqrt(numel(x)));
    
    subplot(2, 2, 3), hold all
    binCenters = bins(2 : end) - diff(bins(1 : 2)) / 2;
    errorbar(binCenters, m, se, '.-')
    set(gca, 'box', 'off', 'xlim', bins([1 end]))
    xlabel('Distamce between tetrodes (mu)')
    ylabel('Spike count correlation')
    
    % can't use fetchn at the end since this would screw up the ordering
    subjectNames{end + 1} = fetch1(acq.Subjects(struct('subject_id', subjectId)), 'subject_name'); %#ok<AGROW>
end

legend(subjectNames)
