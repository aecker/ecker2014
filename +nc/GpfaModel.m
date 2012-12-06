%{
nc.GpfaModel (computed) # Gaussian process factor analysis model

-> nc.GratingConditions
-> ae.SpikesByTrialSet
-> nc.GpfaParams
-> nc.GpfaDataTransforms
---
sigma_n     : double    # GP innovation noise
tolerance   : double    # convergence tolerance for EM algorithm
seed        : bigint    # random number generator seed
model       : longblob  # GPFA model structure
%}

classdef GpfaModel < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.GpfaModel');
        popRel = nc.GratingConditions * ae.SpikesByTrialSet * nc.GpfaDataTransforms * ...
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
            
            stimTime = fetch1(nc.Gratings(key), 'stimulus_time');
            nBins = fix(stimTime / key.bin_size);
            bins = (0 : nBins) * key.bin_size;
            
            % get spikes
            validTrials = (stimulation.StimTrials(key) * nc.GratingTrials(key)) & 'valid_trial = true';
            data = fetch(ae.SpikesByTrial(key) * validTrials, 'spikes_by_trial');
            data = dj.struct.sort(data, {'trial_num', 'unit_id'});
            nUnits = max([data.unit_id]);
            nTrials = numel(data) / nUnits;
            data = reshape(data, nUnits, nTrials);
            x = zeros(nUnits, nBins, nTrials);
            for iTrial = 1 : nTrials
                for iUnit = 1 : nUnits
                    xi = histc(data(iUnit, iTrial).spikes_by_trial, bins);
                    x(iUnit, :, iTrial) = xi(1 : nBins);
                end
            end
            
            % transform data
            formula = fetch1(nc.GpfaDataTransforms & key, 'transform_formula');
            x = eval([formula ';']);
            
            % convert to residuals
            x = bsxfun(@minus, x, mean(x, 3));
            
            % fit GPFA model
            sigmaN = 1e-3;
            tol = 1e-4;
            hash = dj.DataHash(key);
            seed = hex2dec(hash(1 : 8));
            model = GPFA('SigmaN', sigmaN, 'Tolerance', tol, 'Seed', seed);
            model = model.fit(x, [], key.latent_dim);
            
            tuple = key;
            tuple.sigma_n = sigmaN;
            tuple.tolerance = tol;
            tuple.seed = seed;
            tuple.model = struct(model);
            self.insert(tuple);
        end
    end
end
