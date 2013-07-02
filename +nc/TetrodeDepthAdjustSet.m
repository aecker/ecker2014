%{
nc.TetrodeDepthAdjustSet (computed) # fine adjustment of relative depths

-> nc.EvokedLfpProfile
---
%}

classdef TetrodeDepthAdjustSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.TetrodeDepthAdjustSet');
        popRel = nc.EvokedLfpProfile * acq.Subjects ...
            & 'subject_name IN ("Brian", "Albert") AND exp_type = "AcuteGratingExperiment"';
    end

    methods
        function self = TetrodeDepthAdjustSet(varargin)
            self.restrict(varargin{:})
        end
    end

    methods (Access = protected)
        function makeTuples(self, key)

            % some parameters
            first = 2000;
            last = 2300;
            
            % some metadata
            tet = fetchn(nc.EvokedLfpElectrodes & key, 'electrode_num');
            nTet = numel(tet);
            nStim = count(nc.EvokedLfpStims & key);
            [start, Fs] = fetch1(nc.EvokedLfpProfile & key, 'start_time', 'lfp_sampling_rate');
            
            % get evoked LFPs
            [lfp, depths] = fetchn(nc.EvokedLfp * ae.TetrodeDepths & key, ...
                'avg_evoked_lfp', 'depth', 'ORDER BY electrode_num ASC, stim_start_time ASC');
            lfp = reshape([lfp{:}], [numel(lfp{1}), nStim, nTet]);
            depths = reshape(depths, [nStim, nTet]);
            
            % extract feature for alignment: variance of off-response
            ndx = (first - start) / 1000 * Fs : (last - start) / 1000 * Fs;
            SD = permute(std(lfp(ndx, :, :), [], 1), [2 3 1]);
            
            % align tetrodes
            [offset, maxc] = alignTetDepthsRel(depths, SD);

            % insert into database
            self.insert(key)
            for iTet = 1 : numel(tet)
                tuple = key;
                tuple.electrode_num = tet(iTet);
                tuple.depth_adjust = offset(iTet);
                tuple.confidence = maxc(iTet);
                insert(nc.TetrodeDepthAdjust, tuple);
            end
        end
    end
end


function [offset, maxc] = alignTetDepthsRel(depths, feat)
% Align tetrode detphs relative to each other
% AE 2013-02-13

% GP parameters
sn = 5e-6;
sy = 5e-6;
len = 300;

% subtract means for each tetrode
feat = bsxfun(@minus, feat, mean(feat));

maxRange = 200;
nIter = 4;
[nSites, nTet, nFeat] = size(feat);
offset = zeros(1, nTet);
maxc = zeros(1, nTet);
for i = 1 : nIter
    r = maxRange / 2 ^ (i - 1); % divide range by two in each iteration
    range = linspace(-r, r, 100);
    nRange = numel(range);
    for iTet = 1 : nTet
        di = bsxfun(@plus, depths(:, iTet), offset(iTet) + range);
        d = depths(:, setdiff(1 : end, iTet));
        fi = zeros(nSites, nRange, nFeat);
        for iFeat = 1 : nFeat
            f = feat(:, setdiff(1 : end, iTet), iFeat);
            tmp = gpreg(d(:), f(:), di(:), sn, sy, len);
            fi(:, :, iFeat) = reshape(tmp, nSites, nRange);
        end
        flatten = @(x) reshape(permute(x, [1 3 2]), [], size(x, 2));
        xc = corr(flatten(feat(:, iTet, :)), flatten(fi));
        [maxc(iTet), ndx] = max(xc);
        offset(iTet) = offset(iTet) + range(ndx);
    end
end
end


function [Ey, Covy, logL] = gpreg(x, y, xi, sn, sy, len)
% Gaussian process regression
%   [Ey, Covy, logL] = gpreg(x, y, xi, sn, sy, len) performs Gaussian
%   process regression given the data (x, y) and returns expected value Ey
%   and covariance Covy evaluated at locations xi. The independent noise
%   variance is given by sn^2. A Gaussian kernel with spatial length scale
%   len and variance sy^2 is used.
%   
% AE 2013-02-13

k = @(xi, xj) sy ^ 2 * exp(-(bsxfun(@minus, xi, xj) .^ 2) / (2 * len ^ 2));
n = size(x, 1);
K = k(x, x');
Ks = k(x, xi');
L = chol(K + sn ^ 2 * eye(n))';
alpha = L' \ (L \ y);
Ey = Ks' * alpha;
v = L \ Ks;
Ki = k(xi, xi');
Covy = Ki - v' * v;
logL = -(y' * alpha) / 2 - trace(L) - n / 2 * log(2 * pi);
end
