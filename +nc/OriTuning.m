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
ori_fit_rsq             : float     # R^2 of tuning curve fit
ori_mean_rate           : blob      # raw mean firing rates for all orientations
ori_sel_ind             : float     # orientation selectivity index
dir_sel_p = NULL        : float     # p value for direction selectivity (a != b)
pref_dir = NULL         : float     # preferred direction (if applicable)
dir_baseline = NULL     : float     # baseline offset of orientation tuning curve (f_base)
dir_kappa = NULL        : float     # direction tuning width (kappa)
dir_ampl_pref = NULL    : float     # amplitude preferred direction (a)
dir_ampl_null = NULL    : float     # amplitude opposite direction (b)
dir_fit_rsq = NULL      : float     # R^2 of direction tuning curve fit
dir_mean_rate = NULL    : blob      # raw mean firing rates for all directions
dir_sel_ind = NULL      : float     # direction selectivity index

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
            validTrials = validTrialsCompleteBlocks(nc.Gratings(key));
            rel = (validTrials * nc.GratingConditions) * ae.SpikesByTrial(key);
            stimTime = fetch1(nc.Gratings(key), 'stimulus_time');
            nDir = count(nc.GratingConditions(key));
            spikes = ae.SpikesByTrial.spikeCountStruct(rel, [0 stimTime], 'direction / 180 * pi() -> direction');
            spikes = dj.struct.sort(spikes, 'direction');
            directions = [spikes.direction];
            uDir = unique(directions);
            rate = reshape([spikes.spike_count], [], nDir) / stimTime * 1000;
            meanRate = mean(rate, 1);
            
            % TMP: check to ensure that we have the same number of trials
            %      from each condition
            assert(all(~diff(hist(directions, uDir))), 'Block design messed up!!')
            
            % firing rate during fixation/intertrial
            switch fetch1(acq.Stimulation(key), 'exp_type')
                case 'AcuteGratingExperiment'
                    pauseTime = getfield(fetch1(stimulation.StimTrialGroup(key), 'stim_constants'), 'pauseTime'); %#ok
                    delay = 300;
                    fixation = ae.SpikesByTrial.spikeCount(rel, [stimTime + delay, stimTime + pauseTime(1)]);
                    fixation = fixation / (pauseTime(1) - delay) * 1000;
                case {'GratingExperiment', 'mgrad', 'movgrad'}
                    fixTime = min(getParam(stimulation.StimTrials(key), 'holdFixationTime'));
                    fixation = ae.SpikesByTrial.spikeCount(rel, [-fixTime, 0]);
                    fixation = fixation / fixTime * 1000;
                otherwise
                    error('Don''t know what time window to use for fixation period.')
            end
            
            % test for visual responsiveness (adjust for multiple comp).
            p = zeros(nDir, 1);
            for i = 1:nDir
                [~, p(i)] = ttest2(fixation, rate(:, i));
            end
            tuple = key;
            tuple.vis_resp_p = min(1, min(p) * nDir);
            
            % orientation tuning curve
            if any(meanRate > 0)
                [~, maxOri] = max(meanRate);
                a0 = [min(meanRate), 2, uDir(maxOri), log(max(meanRate) - min(meanRate) + 0.01)];
                wmin = 0.8 * min(diff(uDir));
                kmax = log(1/2) / (cos(wmin) - 1);
                opt = optimset('MaxFunEvals', 1e4, 'MaxIter', 1e3, 'Display', 'off');
                a = lsqcurvefit(@nc.OriTuning.oriTunFun, a0, directions(:), rate(:), [0 0 -Inf -Inf], [Inf kmax Inf a0(4)], opt);
                tuple.ori_baseline = a(1);
                tuple.ori_kappa = a(2);
                tuple.pref_ori = mod(a(3), pi);
                tuple.ori_ampl = exp(a(4));
                f = nc.OriTuning.oriTunFun(a, uDir);
                tuple.ori_fit_rsq = mean(f .^ 2) / mean(meanRate .^ 2);
                f = nc.OriTuning.oriTunFun(a, a(3) + [0 pi/2]);
                tuple.ori_sel_ind = 1 - f(2) / f(1);
                
                % Test for significance of orientation tuning
                % we project on a complex exponential with one cycle and asses
                % the statistical significance of its magnitude by randomly
                % permuting the trial labels.
                v = exp(2i * directions)';
                n = 10000;
                nv = zeros(n, 1);
                for i = 1:n
                    nv(i) = abs(rate(randperm(numel(directions))) * v);
                end
                tuple.ori_sel_p = sum(nv > abs(rate(:)' * v)) / n;
            else
                tuple.ori_baseline = 0;
                tuple.ori_kappa = 0;
                tuple.pref_ori = 0;
                tuple.ori_ampl = 0;
                tuple.ori_fit_rsq = 1;
                tuple.ori_sel_ind = 0;
                tuple.ori_sel_p = 1;
            end
            if max(uDir) > pi
                tuple.ori_mean_rate = mean(reshape(meanRate, [], 2), 2)';
            else
                tuple.ori_mean_rate = meanRate;
            end
            
            % direction tuning curve (if applicable)
            if any(meanRate > 0)
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
                        a(3) = mod(a(3) + pi, 2 * pi);
                        tuple.pref_dir = a(3);
                    end
                    tuple.dir_ampl_pref = exp(a(4));
                    tuple.dir_ampl_null = exp(a(5));
                    f = nc.OriTuning.dirTunFun(a, tuple.pref_dir + [0 pi]);
                    tuple.dir_sel_ind = 1 - f(2) / f(1);
                    
                    % significance of direction selectivity (U test)
                    f = nc.OriTuning.dirTunFun(a, uDir);
                    ndx = find(abs(angle(exp(1i * (uDir - a(3))))) < pi / 2 & f > (exp(a(4)) + a(1)) / 2);
                    pref = rate(:, ndx);
                    null = rate(:, mod(ndx + nDir / 2 - 1, nDir) + 1);
                    tuple.dir_fit_rsq = mean(f .^ 2) / mean(meanRate .^ 2);
                    tuple.dir_sel_p = ranksum(pref(:), null(:));
                else
                    tuple.dir_baseline = 0;
                    tuple.dir_kappa = 0;
                    tuple.pref_dir = 0;
                    tuple.dir_ampl_pref = 0;
                    tuple.dir_ampl_null = 0;
                    tuple.dir_fit_rsq = 1;
                    tuple.dir_sel_ind = 0;
                    tuple.dir_sel_p = 1;
                end
                tuple.dir_mean_rate = meanRate;
            end
			insert(self, tuple);
        end
    end
    
    methods
        function varargout = plot(self, varargin)
            args.hdl = gca;
            args.color = 'k';
            args.p = 0.01;
            args = parseVarArgs(args, varargin{:});
            axes(args.hdl);
            data = fetch(self, '*');
            if isnan(data.dir_sel_p)   % orientation
                n = length(data.ori_mean_rate);
                orid = (0 : n) / n * 180;
                oric = linspace(0, 180, 200);
                par = [data.ori_baseline data.ori_kappa data.pref_ori log(data.ori_ampl)];
                f = nc.OriTuning.oriTunFun(par, oric / 180 * pi);
                mr = data.ori_mean_rate;
                mr = [mr mr(1)];
                plot(orid, mr, '.k')
                if data.ori_sel_p < args.p
                    hold on
                    plot(oric, f, 'color', args.color)
                end
                yl = max(max(mr), max(f)) * 1.1;
                set(gca, 'xlim', [0 180], 'xtick', 0 : 90 : 180, 'ylim', [0 yl])
            else   % direction of motion
                n = length(data.dir_mean_rate);
                dird = (0 : n) / n * 360;
                dirc = linspace(0, 360, 200);
                par = [data.dir_baseline data.dir_kappa data.pref_dir log(data.dir_ampl_pref) log(data.dir_ampl_null)];
                f = nc.OriTuning.dirTunFun(par, dirc / 180 * pi);
                mr = data.dir_mean_rate;
                mr = [mr mr(1)];
                plot(dird, mr, '.k')
                if data.ori_sel_p < args.p
                    hold on
                    plot(dirc, f, 'color', args.color)
                end
                yl = max(max(mr), max(f)) * 1.1;
                set(gca, 'xlim', [0 360], 'xtick', 0 : 180 : 360, 'ylim', [0 yl])
            end
            if nargout
                varargout{1} = agrs.hdl;
            end
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
