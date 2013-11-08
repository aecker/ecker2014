%{
nc.GpfaSpontSet (computed) # GPFA model on spontaneous acitvity (intertrial)

-> nc.Gratings
-> ae.SpikesByTrialSet
-> nc.UnitPairSet
-> nc.GpfaParams
-> nc.DataTransforms
---
-> nc.UnitStatsSet
sigma_n             : double            # GP innovation noise
tolerance           : double            # convergence tolerance for EM algorithm
start_seed          : bigint            # random number generator seed
raw_data            : longblob          # raw spike count matrix
transformed_data    : longblob          # transformed spike count matrix
transformed_sd      : longblob          # transformed SDs
unit_ids            : mediumblob        # list of unit ids used
num_units           : tinyint unsigned  # number of units in model
num_trials          : int unsigned      # number of trials used
%}

classdef GpfaSpontSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.GpfaSpontSet');
        popRel = nc.Gratings * ae.SpikesByTrialSet * nc.UnitPairSet ...
            * nc.GpfaParams * nc.DataTransforms * nc.Anesthesia ...
            & nc.AnalysisStims ...
            & 'state = "anesthetized"' ...
            & 'sort_method_num = 5' ...
            & 'max_latent_dim = 1' ...
            & 'kfold_cv = 2' ...
            & 'zscore = 0' ...
            & 'max_instability = 0.1' ...
            & 'transform_num = 5' ...
            & (nc.UnitStatsSet & 'spike_count_start = 30 AND spike_count_end = 2030');
    end
    
    methods 
        function varargout = fetchMatrix(self, rel, varargin)
            % Fetch arbitrary pair data in matrix form.
            %   [M1, M2, ...] = fetchMatrix(self, rel, field1, field2, ...)

            assert(count(self) == 1, 'relvar must be scalar!')
            nFields = numel(varargin);
            % below is the more efficient way of doing:
            % joinedRel = nc.GpfaPairs * self * rel
            joinedRel = nc.GpfaPairs * nc.GpfaSpontSet * rel & self.restrictions;
            [i, j, data{1 : nFields}] = fetchn(joinedRel, 'index_i', 'index_j', varargin{:});
            nUnits = max(j);
            varargout = cell(1, nFields);
            for k = 1 : nFields
                M = NaN(nUnits);
                M(sub2ind([nUnits nUnits], i, j)) = data{k};
                M(sub2ind([nUnits nUnits], j, i)) = data{k};
                varargout{k} = M;
            end
        end

        function varargout = fetchOffdiag(self, rel, varargin)
            % Fetch arbitrary pair data (off-diagonals of matrix)
            %   [val1, val2, ...] = fetchOffdiag(self, rel, field1, field2, ...)

            [varargout{1 : nargout}] = self.fetchMatrix(rel, varargin{1 : nargout});
            offdiag = @(x) x(~tril(ones(size(x))));
            varargout = cellfun(offdiag, varargout, 'uni', false);
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            
            % parameters
            sigmaN = 1e-3;  % GP innovation noise
            tol = 1e-4;     % convergence criterion for fitting
            win = [200 1200]; % analysis window (relative to end of stimulus)
            minRate = 0.25; % spikes/s
            par = fetch(nc.GpfaParams & key, '*');
            
            % Enforce mean firing rate and stability constraints for all cells
            unitConstraints = sprintf('tac_instability < %f AND spike_count_start = 30 AND spike_count_end = 2030', par.max_instability);
            nUnits = count(nc.UnitStats & key & unitConstraints);
            if nUnits <= par.max_latent_dim
                return
            end
            
            % get timestamps for end of stimulus
            events = 'event_type IN ("showStimulus", "endStimulus")';
            t = fetchn(stimulation.StimTrialEvents & key & events, 'event_time', 'ORDER BY event_time');
            t = double(t);
            dt = diff(t);
            dt = dt(2 : 2 : end);
            trials = find(dt > win(2));
            nTrials = numel(trials);
            showStim = t(1 : 2 : end);
            endStim = t(2 : 2 : end);
            
            nBins = fix(diff(win) / par.bin_size);
            bins = (0 : nBins) * par.bin_size;
            
            % get spikes
            nTotalTrials = count(nc.GratingTrials & key);
            rel = ae.SpikesByTrial * nc.GratingTrials * nc.UnitStats;
            data = fetch(rel & key & unitConstraints, 'spikes_by_trial', 'ORDER BY trial_num, unit_id');
            data = reshape(data, nUnits, nTotalTrials);
            Y = zeros(nUnits, nBins, nTrials);
            for iTrial = 1 : nTrials
                ti = trials(iTrial);
                bi = endStim(ti) - showStim(ti) + bins;
                for iUnit = 1 : nUnits
                    xi = histc(data(iUnit, ti).spikes_by_trial, bi);
                    Y(iUnit, :, iTrial) = xi(1 : nBins);
                end
            end
            unitIds = fetchn(nc.UnitStats & key & unitConstraints, 'unit_id');
            
            % apply minimum rate constraint
            fr = mean(Y(:, :), 2) * 1000 / par.bin_size;
            Y = Y(fr > minRate, :, :);
            unitIds = unitIds(fr > minRate);
            
            % partition data for cross-validation
            part = round(linspace(0, nTrials, par.kfold_cv + 1));
            
            % remove cells with zero variance or below in at least one set
            if par.kfold_cv > 1
                for k = 1 : par.kfold_cv
                    train = setdiff(1 : nTrials, part(k) + 1 : part(k + 1));
                    Yk = reshape(Y(:, :, train), numel(unitIds), []);
                    sd = std(Yk, [], 2);
                    Y = Y(sd > 0, :, :);
                    unitIds = unitIds(sd > 0);
                end
            end
            Yraw = Y;
            if numel(unitIds) <= par.max_latent_dim
                return
            end
            
            % transform data
            Y = transform(nc.DataTransforms & key, Y);
            
            % normalize?
            if par.zscore
                sd = std(Y(1 : end, :), [], 2);
                Y = bsxfun(@rdivide, Y, sd);
            else
                sd = [];
            end
            
            % random number generator seed for reproducible behavior
            hash = dj.DataHash(key);
            seed = hex2dec(hash(1 : 8));
            
            % insert into database
            set = key;
            set.sigma_n = sigmaN;
            set.tolerance = tol;
            set.start_seed = seed;
            set.raw_data = Yraw;
            set.transformed_data = Y;
            set.transformed_sd = sd;
            set.unit_ids = unitIds;
            set.num_units = numel(unitIds);
            set.num_trials = nTrials;
            
            % fit GPFA models
            models = [];
            for p = 0 : par.max_latent_dim
                fprintf('p = %d\n', p)
                for k = 1 : par.kfold_cv
                    if par.kfold_cv > 1
                        test = part(k) + 1 : part(k + 1);
                        train = setdiff(1 : nTrials, test);
                    else
                        test = 1 : nTrials;
                        train = 1 : nTrials;
                    end
                    model = GPFA('SigmaN', sigmaN, 'Tolerance', tol, 'Seed', seed);
                    model = model.fit(Y(:, :, train), p, 'hist');
                    
                    m = key;
                    m.latent_dim = p;
                    m.cv_run = k;
                    m.model = struct(model);
                    m.train_set = train;
                    m.test_set = test;
                    m.seed = seed;
                    m.log_like_train = model.logLike(end);
                    [~, ~, m.log_like_test] = model.estX(Y(:, :, test));
                    
                    models = [models; m]; %#ok
                    seed = seed + 1;
                end
            end
            
            % insert all tuples into database (we insert all of them at the
            % end instead doing it as we go to avoid table lock issues)
            self.insert(set);
            insert(nc.GpfaSpont, models);
            
            % insert units that were used
            for iUnit = 1 : numel(unitIds)
                unit = key;
                unit.unit_id = unitIds(iUnit);
                unit.spont_rate = mean(Yraw(iUnit, :)) * 1000 / par.bin_size;
                insert(nc.GpfaSpontUnits, unit);
            end
            
            % insert pairs that were used
            excludePairs = (nc.UnitPairMembership * nc.UnitPairs & key) - (nc.GpfaSpontUnits & key);
            pairs = fetch((nc.GpfaSpontSet * nc.UnitPairs & key) - excludePairs, ...
                nc.UnitPairMembership, 'min(unit_id) -> index_i', 'max(unit_id) -> index_j');
            [~, i] = histc([pairs.index_i], unitIds); i = num2cell(i);
            [~, j] = histc([pairs.index_j], unitIds); j = num2cell(j);
            [pairs.index_i] = deal(i{:});
            [pairs.index_j] = deal(j{:});
            insert(nc.GpfaSpontPairs, pairs);
        end
    end
end
