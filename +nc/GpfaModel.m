%{
nc.GpfaModel (computed) # Gaussian process factor analysis model

-> nc.GratingConditions
-> ae.SpikesByTrialSet
-> nc.GpfaParams
-> nc.DataTransforms
---
sigma_n     : double    # GP innovation noise
tolerance   : double    # convergence tolerance for EM algorithm
seed        : bigint    # random number generator seed
model       : longblob  # GPFA model structure
psth        : longblob  # PSTH
unit_ids    : mediumblob    # list of unit ids used
%}

classdef GpfaModel < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.GpfaModel');
        popRel = nc.GratingConditions * ae.SpikesByTrialSet * nc.DataTransforms * ...
            (pro(ephys.SpikeSet, ephys.Spikes, 'count(subject_id) -> num_units') * nc.GpfaParams) & 'num_units > latent_dim';
            % excluding tuples with less or equal neurons as latent
            % dimensions. can't exclude all of them since sometimes some
            % units don't fire spikes during the stimulus but we have no
            % way of catching this outside the makeTuples function.
    end
    
    methods 
        function self = GpfaModel(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            
            offset = 30; % offset from stimulus onset to account for latencies
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
            Y = Y(unitIds, :, :); %#ok
            
            % transform data
            formula = fetch1(nc.DataTransforms & key, 'formula');
            Y = eval(strrep(formula, 'x', 'Y'));
            
            % convert to residuals
            psth = mean(Y, 3);
            Y = bsxfun(@minus, Y, psth);
            
            % fit GPFA model
            sigmaN = 1e-3;
            tol = 1e-4;
            hash = dj.DataHash(key);
            seed = hex2dec(hash(1 : 8));
            model = GPFA('SigmaN', sigmaN, 'Tolerance', tol, 'Seed', seed);
            model = model.fit(Y, [], key.latent_dim);
            
            tuple = key;
            tuple.sigma_n = sigmaN;
            tuple.tolerance = tol;
            tuple.seed = seed;
            tuple.model = struct(model);
            tuple.psth = psth;
            tuple.unit_ids = unitIds;
            self.insert(tuple);
        end
    end
end
