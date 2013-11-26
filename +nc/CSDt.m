%{
nc.CSDt (computed) # CSD based on total adjustments

-> nc.EvokedLfpProfile
---
csd_complete    : mediumblob    # CSD of entire trial
csd_complete_t  : mediumblob    # times for CSD
csd_on          : mediumblob    # CSD of on-response (muV/mm^2)
csd_on_t        : mediumblob    # times for on response
csd_off         : mediumblob    # CSD of off-response
csd_off_t       : mediumblob    # times for off-response
csd_depths      : mediumblob    # depths corresponding to pixels
layer4_depth    : double        # depth of layer 4 based on adjusted tet depths
csd_source_t    : double        # time of csd source
csd_sink_t      : double        # time of csd sink
%}

classdef CSDt < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.CSDt');
        popRel = nc.EvokedLfpProfile2;
    end
    
    methods 
        function self = CSDt(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            
            % some parameters
            n = 100;
            sd = 150;
            on = [-100 300];
            off = [1900 2300];
            
            % some metadata
            tet = fetchn(ae.TetrodeProperties & key, 'electrode_num');
            nTet = numel(tet);
            nStim = count(nc.EvokedLfpStims & key);
            [start, stop, Fs] = fetch1(nc.EvokedLfpProfile2 & key, ...
                'start_time', 'stop_time', 'lfp_sampling_rate');

            [lfp, depths] = fetchn(nc.EvokedLfp2 * ae.TetrodeDepths ...
                * nc.TetrodeDepthAdjust & key, ...
                'avg_evoked_lfp', 'depth + depth_adjust -> d', ...
                'ORDER BY electrode_num ASC, stim_start_time ASC');
            lfp = reshape([lfp{:}], [numel(lfp{1}), nStim, nTet]);
            depths = reshape(depths, [nStim, nTet]);
            
            
            % estimate white matter plane
            [dtw, x, y] = fetchn(ae.TetrodeProperties & key, ...
                'depth_to_brain + depth_to_wm -> d', 'loc_x', 'loc_y', 'ORDER BY electrode_num');
            b = robustfit([x y], dtw);
            wm = b(1) + [x y] * b(2: 3);
            
            % get evoked LFPs
%             [lfp, depths] = fetchn(nc.EvokedLfp2 * ae.TetrodeDepths * ae.TetrodeProperties & key, ...
%                 'avg_evoked_lfp', 'depth + depth_to_brain -> d', ...
%                 'ORDER BY electrode_num, stim_start_time');
%             [lfp, depths] = fetchn(nc.EvokedLfp2 * ae.TetrodeDepths * ae.TetrodeProperties & key, ...
%                 'avg_evoked_lfp', 'depth - depth_to_wm -> d', ...
%                 'ORDER BY electrode_num, stim_start_time');
%             lfp = reshape([lfp{:}], [numel(lfp{1}), nStim, nTet]);
%             depths = reshape(depths, [nStim, nTet]);
%             depths = bsxfun(@minus, depths, wm');
            
%             ndx = ~isnan(depths(1, :));
%             depths = depths(:, ndx);
%             lfp = lfp(:, :, ndx);
           
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
            [~, dNdx] = max(std(csd(:, onNdx), [], 2));
            [~, tNdx] = max(csd(dNdx, onNdx));
            tuple.layer4_depth = d(dNdx + 1);
            tuple.csd_depths = d(2 : end - 1) - d(dNdx + 1);
            tuple.csd_source_t = tuple.csd_on_t(tNdx);
            [~, tNdx] = min(csd(dNdx, onNdx));
            tuple.csd_sink_t = tuple.csd_on_t(tNdx);
            self.insert(tuple);
        end
    end
end
