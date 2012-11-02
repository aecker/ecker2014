%{
nc.GpfaModel (computed) # Gaussian process factor analysis model

-> nc.GratingConditions
-> ae.SpikesByTrialSet
latent_dim  : int       # number of latent dimensions
---
sigma_n     : double    # GP innovation noise
tolerance   : double    # convergence tolerance for EM algorithm
seed        : int       # random number generator seed
bin_size    : int       # bin size (ms)
model       : longblob  # GPFA model structure
%}

classdef GpfaModel < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.GpfaModel');
        popRel = nc.GratingConditions * ae.SpikesByTrialSet;
    end
    
    methods 
        function self = GpfaModel(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            
            binSize = 100;
            stimTime = fetch1(nc.Gratings(key), 'stimulus_time');
            nBins = fix(stimTime / binSize);
            bins = (0 : nBins) * binSize;
            
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
                    yi = histc(data(iUnit, iTrial).spikes_by_trial, bins);
                    Y(iUnit, :, iTrial) = yi(1 : nBins);
                end
            end
            Y = 2 * sqrt(Y + 3/8);  % stabilize variance (Anscombe transf.)
            
            % fit GPFA model
            p = 3;
            sigmaN = 1e-3;
            tol = 1e-4;
            hash = dj.DataHash(key);
            seed = hex2dec(hash(1 : 8));
            model = GPFA('SigmaN', sigmaN, 'Tolerance', tol, 'Seed', seed);
            model = model.fit(Y, p);
            
            key.latent_dim = p;
            tuple = key;
            tuple.sigma_n = sigmaN;
            tuple.tolerance = tol;
            tuple.seed = seed;
            tuple.bin_size = binSize;
            tuple.model = struct(model);
            self.insert(tuple);
        end
    end
end
