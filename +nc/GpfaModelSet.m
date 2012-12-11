%{
nc.GpfaModelSet (computed) # Gaussian process factor analysis model

-> nc.GratingConditions
-> ae.SpikesByTrialSet
-> nc.GpfaParams
-> nc.DataTransforms
---
sigma_n             : double            # GP innovation noise
tolerance           : double            # convergence tolerance for EM algorithm
seed                : bigint            # random number generator seed
raw_data            : longblob          # raw spike count matrix
transformed_data    : longblob          # transformed spike count matrix
psth                : longblob          # PSTH
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
            formula = fetch1(nc.DataTransforms & key, 'formula');
            Y = eval(strrep(formula, 'x', 'Y'));
            
            % convert to residuals
            psth = mean(Y, 3);
            Y = bsxfun(@minus, Y, psth);

            % random number generator seed for reproducible behavior
            hash = dj.DataHash(key);
            seed = hex2dec(hash(1 : 8));

            % insert into database
            tuple = key;
            tuple.sigma_n = sigmaN;
            tuple.tolerance = tol;
            tuple.seed = seed;
            tuple.raw_data = Yraw;
            tuple.transformed_data = Y;
            tuple.psth = psth;
            tuple.unit_ids = unitIds;
            tuple.num_units = numel(unitIds);
            tuple.num_trials = nTrials;
            self.insert(tuple);

            % partition data for cross-validation
            nTrials = size(Y, 3);
            part = round(linspace(0, nTrials, key.kfold_cv + 1));
            
            % fit GPFA models
            for p = 1 : pmax
                for k = 1 : key.kfold_cv
                    test = part(k) + 1 : part(k + 1);
                    train = setdiff(1 : nTrials, test);
                    model = GPFA('SigmaN', sigmaN, 'Tolerance', tol, 'Seed', seed);
                    model = model.fit(Y(:, :, train), p);
                    
                    tuple = key;
                    tuple.latent_dim = p;
                    tuple.cv_run = k;
                    tuple.model = struct(model);
                    tuple.train_set = train;
                    tuple.test_set = test;
                    tuple.seed = seed;
                    tuple.log_like_train = model.logLike(end);
                    [~, ~, tuple.log_like_test] = model.estX(Y(:, :, test));
                    insert(nc.GpfaModel, tuple);
                    
                    seed = seed + 1;
                end
            end
        end
    end
end
