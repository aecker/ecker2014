%{
nc.GpfaModelSet (computed) # Gaussian process factor analysis model

-> nc.GratingConditions
-> ae.SpikesByTrialSet
-> nc.UnitPairSet
-> nc.GpfaParams
-> nc.DataTransforms
control             : boolean           # control model (first 500 ms only)
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
num_trials          : tinyint unsigned  # number of trials in model
%}

classdef GpfaModelSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.GpfaModelSet');
        popRel = nc.Gratings * nc.GratingConditions * ae.SpikesByTrialSet ...
            * nc.UnitPairSet * nc.GpfaParams * nc.DataTransforms ...
            & 'trials_per_cond >= 20' ...
            & (nc.UnitStatsSet & 'spike_count_start = 30 AND spike_count_end = 530') ...
            & (nc.UnitStatsSet & 'spike_count_start = 30 AND spike_count_end = stimulus_time + 30');
    end
    
    methods 
        function self = GpfaModelSet(varargin)
            self.restrict(varargin{:})
        end

        function varargout = fetchMatrix(self, rel, varargin)
            % Fetch arbitrary pair data in matrix form.
            %   [M1, M2, ...] = fetchMatrix(self, rel, field1, field2, ...)

            assert(count(self) == 1, 'relvar must be scalar!')
            nFields = numel(varargin);
            % below is the more efficient way of doing:
            % joinedRel = nc.GpfaPairs * self * rel
            joinedRel = nc.GpfaPairs * nc.GpfaModelSet * rel & self.restrictions;
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
            offset = 30;    % offset from stimulus onset to account for latencies
            par = fetch(nc.GpfaParams & key, '*');
            
            % Enforce mean firing rate and stability constraints for all cells
            unitConstraints = sprintf('mean_rate_cond > %f AND tac_instability < %f AND spike_count_start = %d AND spike_count_end = %d', ...
                par.min_rate, par.max_instability, offset, 500 + offset);
            unitStats = nc.UnitStats * nc.UnitStatsConditions;
            nUnits = count(unitStats & key & unitConstraints);
            if nUnits <= par.max_latent_dim
                return
            end
            
            stimTime = fetch1(nc.Gratings & key, 'stimulus_time');
            assert(any(stimTime == [500 2000]), 'Stimulus time must be 500 or 2000 ms!')
            
            for stimTimeLimit = unique([500 stimTime])

                nBins = fix(stimTimeLimit / par.bin_size);
                bins = offset + (0 : nBins) * par.bin_size;

                % get spikes
                nTrials = count(nc.GratingTrials & key);
                rel = ae.SpikesByTrial * nc.GratingTrials * unitStats;
                data = fetch(rel & key & unitConstraints, 'spikes_by_trial', 'ORDER BY trial_num, unit_id');
                data = reshape(data, nUnits, nTrials);
                Y = zeros(nUnits, nBins, nTrials);
                for iTrial = 1 : nTrials
                    for iUnit = 1 : nUnits
                        xi = histc(data(iUnit, iTrial).spikes_by_trial, bins);
                        Y(iUnit, :, iTrial) = xi(1 : nBins);
                    end
                end
                unitIds = fetchn(unitStats & key & unitConstraints, 'unit_id');

                % partition data for cross-validation
                part = round(linspace(0, nTrials, par.kfold_cv + 1));

                % remove cells with zero variance in at least one set
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
                key.control = stimTimeLimit < stimTime;
                set = key;
                set.spike_count_start = offset;
                set.spike_count_end = stimTimeLimit + offset;
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
                            train = setdiff(1 : nTrials, train);
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
                insert(nc.GpfaModel, models);

                % insert units that were used
                for unitId = unitIds'
                    unit = key;
                    unit.unit_id = unitId;
                    insert(nc.GpfaUnits, unit);
                end

                % insert pairs that were used
                excludePairs = (nc.UnitPairMembership * nc.UnitPairs * nc.GratingConditions & key) - (nc.GpfaUnits & key);
                pairs = fetch((nc.GpfaModelSet * nc.UnitPairs & key) - excludePairs, ...
                    nc.UnitPairMembership, 'min(unit_id) -> index_i', 'max(unit_id) -> index_j');
                [~, i] = histc([pairs.index_i], unitIds); i = num2cell(i);
                [~, j] = histc([pairs.index_j], unitIds); j = num2cell(j);
                [pairs.index_i] = deal(i{:});
                [pairs.index_j] = deal(j{:});
                insert(nc.GpfaPairs, pairs);
            end
        end
    end
end
