%{
nc.CSD (computed) # Current source density of LFP

-> nc.TetrodeDepthAdjustSet
-> nc.CSDParams
---
csd_complete    : mediumblob    # CSD of entire trial
csd_complete_t  : mediumblob    # times for CSD
csd_on          : mediumblob    # CSD of on-response
csd_on_t        : mediumblob    # times for on response
csd_off         : mediumblob    # CSD of off-response
csd_off_t       : mediumblob    # times for off-response
csd_depths      : mediumblob    # depths corresponding to pixels
layer4_depth    : double        # depth of layer 4 based on adjusted tet depths
csd_source_t    : double        # time of csd source
csd_sink_t      : double        # time of csd sink
%}

classdef CSD < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.CSD');
        popRel = nc.TetrodeDepthAdjustSet * nc.CSDParams;
    end
    
    methods 
        function self = CSD(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            
            % some parameters
            restr = sprintf('confidence > %.15f', key.min_confidence);
            n = 100;
            sd = 150;
            on = [-100 300];
            off = [1900 2300];
            
            % some metadata
            tet = fetchn(nc.TetrodeDepthAdjust & key & restr, 'electrode_num');
            nTet = numel(tet);
            nStim = count(nc.EvokedLfpStims & key);
            [start, stop, Fs] = fetch1(nc.EvokedLfpProfile & key, ...
                'start_time', 'stop_time', 'lfp_sampling_rate');
            
            % get evoked LFPs
            [lfp, depths] = fetchn(nc.EvokedLfp * ae.TetrodeDepths ...
                * nc.TetrodeDepthAdjust & key & restr, ...
                'avg_evoked_lfp', 'depth + depth_adjust -> d', ...
                'ORDER BY electrode_num ASC, stim_start_time ASC');
            lfp = reshape([lfp{:}], [numel(lfp{1}), nStim, nTet]);
            depths = reshape(depths, [nStim, nTet]);
            
            % average across tetrodes with adjusted depths and upsample
            d = linspace(min(depths(:)), max(depths(:)), n);
            mlfp = zeros(n, size(lfp, 1));
            for i = 1 : n
                w = exp(-0.5 * (d(i) - depths(:)) .^ 2 / sd ^ 2);
                w = w / sum(w);
                mlfp(i, :) = lfp(1 : end, :) * w;
            end
            
            % compute current source density
            dz = diff(d(1 : 2)) / 1000;
            csd = diff(mlfp, 2) / dz ^ 2;
            t = start : 1000 / Fs : stop;
            
            tuple = key;
            tuple.csd_complete = csd;
            tuple.csd_complete_t = t;
            onNdx = t >= on(1) & t <= on(2);
            tuple.csd_on = csd(:, onNdx);
            tuple.csd_on_t = t(onNdx);
            offNdx = t >= off(1) & t <= off(2);
            tuple.csd_off = csd(:, offNdx);
            tuple.csd_off_t = t(offNdx);
            [i, j] = find(csd(:, onNdx) == max(reshape(csd(:, onNdx), [], 1)));
            tuple.layer4_depth = d(i + 1);
            tuple.csd_depths = d(2 : end - 1) - d(i + 1);
            tuple.csd_source_t = tuple.csd_on_t(j);
            [~, j] = find(csd(:, onNdx) == min(reshape(csd(:, onNdx), [], 1)));
            tuple.csd_sink_t = tuple.csd_on_t(j);
            self.insert(tuple);
        end
    end
end
