function varargout = corrStructPlots(varargin)
% Dependence of noise correlations on firing rates
% AE 2012-08-06

args.subjectIds = {23 8 9 11};
args.sortMethodNum = 5;
args.spikeCountEnd = 500;
args.contam = 0.1;
args.stability = 0.1;
args.rateDepType = 'lin';  % lin/sqrt/log
args.adjustPred = false;
args = parseVarArgs(args, varargin{:});

subjectNames = {};

set(figure, 'DefaultAxesColorOrder', [0 0 0; 0 0 1; 1 0 0; 1 0 1; 0 0.5 0])
k = 0;
hhdl = zeros(1, numel(args.subjectIds));
for subjectId = args.subjectIds(:)'
    k = k + 1;
    
    % restrictions
    key = struct('subject_id', subjectId{1}, ...
        'sort_method_num', args.sortMethodNum, ...
        'spike_count_end', args.spikeCountEnd);
    excludePairs = nc.UnitPairMembership(key) & ( ...
        (ephys.SingleUnit(key) & sprintf('fp + fn > %.16f', args.contam)) + ...
        (nc.UnitStats(key) & sprintf('stability > %.16f', args.stability)));
    
    % obtain data
    [r, fr, d, rs] = fetchn(nc.NoiseCorrelations(key) - excludePairs, ...
        'r_noise_avg', 'geom_mean_rate', 'distance', 'r_signal');
    
    % throw out nans and non-spiking pairs
    ndx = ~isnan(r) & fr > 0;
    r = r(ndx);
    fr = fr(ndx);
    d = d(ndx);
    rs = rs(ndx);
    
    % fit regression model
    %   [this isn't completely correct yet since the predictors aren't
    %    independent; need to think about how to fix that]
    par = regress(r, [fr, rs, d, ones(size(d))]);
    if nargout
        varargout{1}(k, :) = par;
    end
    binc = @(b) b(2 : end) - diff(b(end - 1 : end)) / 2;
    
    % firing rate dependence
    switch args.rateDepType
        case 'lin'
            frbins = 0 : 5 : 70;
            [count, frbin] = histc(fr, frbins);
            lbl = '%s';
            xl = [0 40];
        case 'sqrt'
            frbins = 0 : 0.5 : 8;
            [count, frbin] = histc(sqrt(fr), frbins);
            lbl = 'sqrt(%s)';
            xl = [0 6];
        case 'log'
            frbins = [-Inf, -1 : 0.25 : 2];
            [count, frbin] = histc(log10(fr), frbins);
            lbl = 'log10(%s)';
            xl = [-1.25 2];
    end
    sz = [numel(frbins) - 1, 1];
    m = accumarray(frbin, r, sz, @mean);
    m(count(1 : end - 1) < 3) = NaN;
    se = accumarray(frbin, r, sz, @(x) std(x) / sqrt(numel(x)));
    
    subplot(2, 2, 1), hold all
    hdl = errorbar(binc(frbins), m, se, '.');
    plot(binc(frbins), evalReg(frbins, binc(frbins), par, fr, rs, d, 'fr', args.adjustPred), 'color', get(hdl, 'color'))
    set(gca, 'box', 'off', 'xlim', xl)
    xlabel(sprintf(lbl, 'Geometric mean firing rate [spikes/sec]'))
    ylabel('Spike count correlation')
    
    % signal correlation dependence
    rsbins = -1 : 0.5 : 1;
    rsbins(end) = 1.00001;
    [count, rsbin] = histc(rs, rsbins);
    sz = [numel(rsbins) - 1, 1];
    m = accumarray(rsbin, r, sz, @mean);
    m(count(1 : end - 1) < 5) = NaN;
    se = accumarray(rsbin, r, sz, @(x) std(x) / sqrt(numel(x)));
    
    subplot(2, 2, 2), hold all
    hdl = errorbar(binc(rsbins), m, se, '.');
    plot(binc(rsbins), evalReg(rsbins, binc(rsbins), par, fr, rs, d, 'rs', args.adjustPred), 'color', get(hdl, 'color'))
    set(gca, 'box', 'off', 'xlim', rsbins([1 end]))
    xlabel('Signal correlation')
    ylabel('Spike count correlation')
    
    % distance dependence
    if max(d) < 1
        dbins = 0 : 0.18 : 4;
    else
        dbins = 0 : 0.5 : 4;
    end
    [count, dbin] = histc(d, dbins);
    sz = [numel(dbins) - 1, 1];
    m = accumarray(dbin, r, sz, @mean);
    m(count(1 : end - 1) < 5) = NaN;
    se = accumarray(dbin, r, sz, @(x) std(x) / sqrt(numel(x)));
    
    subplot(2, 2, 3), hold all
    hdl = errorbar(binc(dbins), m, se, '.');
    hhdl(k) = plot(binc(dbins), evalReg(dbins, binc(dbins), par, fr, rs, d, 'd', args.adjustPred), 'color', get(hdl, 'color'));
    set(gca, 'box', 'off', 'xlim', dbins([1 end]))
    xlabel('Distamce between tetrodes (mu)')
    ylabel('Spike count correlation')
    
    % can't use fetchn at the end since this would screw up the ordering
    subjectName = fetchn(acq.Subjects(struct('subject_id', subjectId{1})), 'subject_name');
    subjectNames{end + 1} = sprintf('%s ', subjectName{:}); %#ok<AGROW>
end

legend(hhdl, subjectNames)


function rp = evalReg(bins, bc, par, fr, rs, d, marg, adjust)

rp = zeros(size(bc));
for i = 1 : numel(rp)
    if adjust
        switch marg
            case 'fr'
                rp(i) = par(1) * bc(i) + ...
                    par(2) * mean(rs(fr >= bins(i) & fr < bins(i + 1))) + ...
                    par(3) * mean(d(fr >= bins(i) & fr < bins(i + 1))) + ...
                    par(4);
            case 'rs'
                rp(i) = par(1) * mean(fr(rs >= bins(i) & rs < bins(i + 1))) + ...
                    par(2) * bc(i) + ...
                    par(3) * mean(d(rs >= bins(i) & rs < bins(i + 1))) + ...
                    par(4);
            case 'd'
                rp(i) = par(1) * mean(fr(d >= bins(i) & d < bins(i + 1))) + ...
                    par(2) * mean(rs(d >= bins(i) & d < bins(i + 1))) + ...
                    par(3) * bc(i) + ...
                    par(4);
        end
    else
        switch marg
            case 'fr'
                rp(i) = par(1) * bc(i) + par(2) * mean(rs) + par(3) * mean(d) + par(4);
            case 'rs'
                rp(i) = par(1) * mean(fr) + par(2) * bc(i) + par(3) * mean(d) + par(4);
            case 'd'
                rp(i) = par(1) * mean(fr) + par(2) * mean(rs) + par(3) * bc(i) + par(4);
        end
    end
end
