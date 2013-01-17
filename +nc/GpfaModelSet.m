%{
nc.GpfaModelSet (computed) # Gaussian process factor analysis model

-> nc.GratingConditions
-> ae.SpikesByTrialSet
-> nc.GpfaParams
-> nc.DataTransforms
---
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
        popRel = ae.SpikesByTrialSet * nc.DataTransforms ...
            * pro(nc.GratingConditions, nc.GratingTrials * stimulation.StimTrials('valid_trial=true'), 'count(subject_id) -> n_trials') ...
            * (pro(ephys.SpikeSet, ephys.Spikes, 'count(subject_id) -> n_units') * nc.GpfaParams) ...
            & 'n_units > 10 AND n_trials >= 10';
            % excluding tuples with less or equal neurons as latent
            % dimensions. can't exclude all of them since sometimes some
            % units don't fire spikes during the stimulus but we have no
            % way of catching this outside the makeTuples function.
    end
    
    methods 
        function self = GpfaModelSet(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            
            % parameters
            sigmaN = 1e-3;  % GP innovation noise
            tol = 1e-4;     % convergence criterion for fitting
            pmax = 10;      % max number of latent factors
            offset = 30;    % offset from stimulus onset to account for latencies
            
            stimTime = fetch1(nc.Gratings(key), 'stimulus_time');
            nBins = fix(stimTime / key.bin_size);
            bins = offset + (0 : nBins) * key.bin_size;
            
            % get spikes
            validTrials = (stimulation.StimTrials(key) * nc.GratingTrials(key)) & 'valid_trial = true';
            data = fetch(ae.SpikesByTrial(key) * validTrials, 'spikes_by_trial');
            data = dj.struct.sort(data, {'trial_num', 'unit_id'});
            nUnits = max([data.unit_id]);
            nTrials = numel(data) / nUnits;
            data = reshape(data, nUnits, nTrials);
            Y = zeros(nUnits, nBins, nTrials);
            for iTrial = 1 : nTrials
                for iUnit = 1 : nUnits
                    xi = histc(data(iUnit, iTrial).spikes_by_trial, bins);
                    Y(iUnit, :, iTrial) = xi(1 : nBins);
                end
            end
            
            % remove non-spiking and low-firing-rate cells
            minRate = 0.5;  % spikes/sec
            m = mean(Y(1 : nUnits, :), 2) / key.bin_size * 1000;
            unitIds = find(m > minRate);
            Y = Y(unitIds, :, :);
            Yraw = Y;
            
            % transform data
            Y = transform(nc.DataTransforms & key, Y);
            
            % normalize?
            if key.zscore
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
            
            % insert units that were used
            units = [];
            for unitId = unitIds'
                unit = key;
                unit.unit_id = unitId;
                units = [units; unit]; %#ok
            end

            % partition data for cross-validation
            nTrials = size(Y, 3);
            part = round(linspace(0, nTrials, key.kfold_cv + 1));
            
            % fit GPFA models
            models = [];
            for p = 0 : pmax
                for k = 1 : key.kfold_cv
                    test = part(k) + 1 : part(k + 1);
                    train = setdiff(1 : nTrials, test);
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
            insert(nc.GpfaUnits, units);
            insert(nc.GpfaModel, models);
        end
    end
end
