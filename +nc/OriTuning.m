%{
nc.OriTuning (computed) # my newest table

-> nc.OriTuningSet
-> ephys.Spikes
contrast                : float     # stimulus contrast
-----
vis_resp_p              : float     # p value for visual responsiveness (t-test)
ori_sel_p               : float     # p value for orientation selectivity (Rayleigh test)
pref_ori                : float     # preferred orientation (phi)
ori_baseline            : float     # baseline offset of orientation tuning curve (f_base)
ori_kappa               : float     # orientation tuning width (kappa)
ori_ampl                : float     # orientation tuning curve amplitude (a)
ori_mean_rate           : blob      # raw mean firing rates for all orientations
dir_sel_p = NULL        : float     # p value for direction selectivity (a != b)
pref_dir = NULL         : float     # preferred direction (if applicable)
dir_baseline = NULL     : float     # baseline offset of orientation tuning curve (f_base)
dir_kappa = NULL        : float     # direction tuning width (kappa)
dir_ampl_pref = NULL    : float     # amplitude preferred direction (a)
dir_ampl_null = NULL    : float     # amplitude opposite direction (b)
dir_mean_rate = NULL    : blob      # raw mean firing rates for all directions

%}

% Orientation tuning curve model:
%   f(theta) = f_base + a * exp(kappa * (cos(theta - phi) - 1))
%
% Direction tuning curve model (a > b by convention):
%   f(theta) = f_base + a * exp(kappa * (cos(theta - phi) - 1))
%                     + b * exp(kappa * (cos(theta - phi - pi) - 1))

classdef OriTuning < dj.Relvar

	properties(Constant)
		table = dj.Table('nc.OriTuning')
	end

	methods
		function self = OriTuning(varargin)
			self.restrict(varargin)
		end

		function makeTuples(self, key)
            fprintf('Unit %d\n', key.unit_id)
            
            % get spike counts by condition
            stimTime = fetch1(nc.Gratings(key), 'stimulus_time');
            rel = (ae.SpikesByTrial(key) & stimulation.StimTrials('valid_trial = true')) ...
                * nc.GratingTrials(key) * nc.GratingConditions(key);
            spikes = ae.SpikesByTrial.spikeCountStruct(rel, [0 stimTime], 'direction / 180 * pi() -> direction');
            spikes = dj.struct.sort(spikes, 'direction');
            directions = [spikes.direction];
            uDir = unique(directions);
            nDir = numel(uDir);
            rate = reshape([spikes.spike_count], [], nDir) / stimTime * 1000;
            meanRate = mean(rate, 1);
            
            % firing rate during fixation/intertrial
            switch fetch1(acq.Stimulation(key), 'exp_type')
                case 'AcuteGratingExperiment'
                    pauseTime = getfield(fetch1(stimulation.StimTrialGroup(key), 'stim_constants'), 'pauseTime'); %#ok
                    delay = 300;
                    fix = ae.SpikesByTrial.spikeCount(rel, [stimTime + delay, stimTime + pauseTime(1)]);
                    fix = fix / (pauseTime(1) - delay) * 1000;
                case 'GratingExperiment'
                    error('TODO')
            end
            
            % test for visual responsiveness (adjust for multiple comp).
            p = zeros(nDir, 1);
            for i = 1:nDir
                p(i) = ttest2(fix, rate(:, i));
            end
            tuple = key;
            tuple.vis_resp_p = min(1, min(p) * nDir);
            
            % orientation tuning curve
            [~, maxOri] = max(meanRate);
            a0 = [min(meanRate), 2, uDir(maxOri), log(max(meanRate) - min(meanRate))];
            wmin = 0.8 * min(diff(uDir));
            kmax = log(1/2) / (cos(wmin) - 1);
            opt = optimset('MaxFunEvals', 1e4, 'MaxIter', 1e3, 'Display', 'off');
            a = lsqcurvefit(@nc.OriTuning.oriTunFun, a0, directions(:), rate(:), [0 0 -Inf -Inf], [Inf kmax Inf a0(4)], opt);
            tuple.ori_baseline = a(1);
            tuple.ori_kappa = a(2);
            tuple.pref_ori = mod(a(3), pi);
            tuple.ori_ampl = exp(a(4));
            if max(uDir) > pi
                tuple.ori_mean_rate = mean(reshape(meanRate, [], 2), 2)';
            else
                tuple.ori_mean_rate = meanRate;
            end
            
            % Test for significance of orientation tuning 
            % we project on a complex exponential with one cycle and asses
            % the statistical significance of its magnitude by randomly
            % permuting the trial labels.
            v = exp(2i * directions)';
            n = 2000;
            nv = zeros(n, 1);
            for i = 1:n
                nv(i) = abs(rate(randperm(numel(directions))) * v);
            end
            tuple.ori_sel_p = sum(nv > abs(rate(:)' * v)) / n;

            % direction tuning curve (if applicable)
            if max(uDir) > pi
                a0(5) = log(meanRate(mod(maxOri - 1 + ceil(nDir/2), nDir) + 1) - a0(1));
                kmax = log(1/2) / (cos(wmin / 2) - 1);
                a = lsqcurvefit(@nc.OriTuning.dirTunFun, a0, directions(:), rate(:), [0 0 -Inf -Inf -Inf], [Inf kmax Inf a0(4) a0(4)], opt);
                tuple.dir_baseline = a(1);
                tuple.dir_kappa = a(2);
                if a(4) > a(5)
                    tuple.pref_dir = mod(a(3), 2 * pi);
                else
                    a(4:5) = a([5 4]);
                    tuple.pref_dir = mod(a(3) + pi, 2 * pi);
                end
                tuple.dir_ampl_pref = exp(a(4));
                tuple.dir_ampl_null = exp(a(5));
                
                % significance of direction selectivity (U test)
                f = nc.OriTuning.dirTunFun(a, uDir);
                ndx = find(abs(angle(exp(1i * (uDir - a(3))))) < pi / 2 & f > (exp(a(4)) + a(1)) / 2);
                pref = rate(:, ndx);
                null = rate(:, mod(ndx + nDir / 2 - 1, nDir) + 1);
                tuple.dir_sel_p = ranksum(pref(:), null(:));
                tuple.dir_mean_rate = meanRate;
            end
			insert(self, tuple)
        end
    end
    
    methods(Static, Access = private)
        function y = dirTunFun(a, theta)
            y = a(1) + exp(a(4) + a(2) * (cos(theta - a(3)) - 1)) ...
                     + exp(a(5) + a(2) * (cos(theta - a(3) + pi) - 1));
        end
        
        function y = oriTunFun(a, theta)
            y = a(1) + exp(a(4) + a(2) * (cos(2 * (theta - a(3))) - 1));
        end
    end
end
