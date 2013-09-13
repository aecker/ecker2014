% LNP model with stimulus and LFP as inputs and exponential non-linearity.
%
% The model we fit is:
%   r = exp(b*psth + c*lfp + const)
%
% The PSTH is estimated independently for each bin.
%
% bin_size is assumed to be 50 ms currently (need to check if other values
% are reasonable too)
%
% To populate the table only for the electrode where the cell was recorded:
%   populate(nc.LnpModel3, ephys.Spikes)

%{
nc.LnpModel3 (computed) # Firing rate prediction from LFP

-> nc.LnpModel3Spikes
-> nc.LnpModel3Lfp
-> nc.LnpModel3Params
---
params = NULL   : blob          # all parameters (#conditions x #basisfun + 1)
deviance = NULL : double        # deviance of model fit
stats = NULL    : mediumblob    # stats returned by glmfit
lfp_param = NULL: double        # parameter for lfp dependence (scalar)
warning         : boolean       # was a warning issued during fitting?
%}

classdef LnpModel3 < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.LnpModel3');
        popRel = nc.LnpModel3Set * nc.LnpModel3Params * nc.Gratings * nc.LnpModel3Spikes * ephys.Spikes * nc.LnpModel3Lfp ...
            & 'min_trials >= num_trials AND stimulus_time >= stim_time AND mean_rate > 1';
    end
    
    methods 
        function self = LnpModel3(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            
            binSize = fetch1(nc.LnpModel3Set(key), 'bin_size');
            
            % number of trials to use to fit the model
            if key.num_trials == -1
                nTrials = fetch1(nc.LnpModel3Set(key), 'min_trials');
            else
                nTrials = key.num_trials;
            end
            
            % number of bins to use within each trial
            if key.stim_time == -1
                nBins = fix(fetch1(nc.Gratings(key), 'stimulus_time') / binSize);
            else
                nBins = fix(key.stim_time / binSize);
            end
            
            % LFP data
            lfp = fetch1(nc.LnpModel3Lfp(key), 'lfp_data');
            lfp = lfp(1 : nBins, 1 : nTrials);
            lfp = lfp(:);
            
            % spike data
            spikes = fetch1(nc.LnpModel3Spikes(key), 'spike_data');
            spikes = spikes(1 : nBins, 1 : nTrials);
            spikes = spikes(:);
            
            % design matrix for stimulus
            stim = repmat(eye(nBins), nTrials, 1);
            
            % fit GLM
            lastwarn('');
            switch key.method
                case 'glm'
                    [w, dev, stats] = glmfit([stim, lfp], spikes, 'poisson', 'constant', 'off');
                case 'net'
                    [w, stats] = lassoglm([stim, lfp], spikes, 'poisson', 'cv', 10, 'lambda', 10.^(-6 : 0), 'alpha', 0.8, 'standardize', false);
                    stats.w = w;
                    ndx = stats.IndexMinDeviance;
                    dev = stats.Deviance(ndx);
                    w = [stats.Intercept(ndx); w(:, ndx)];
            end
            
            % insert into db
            tuple = key;
            tuple.params = w;
            tuple.deviance = dev;
            tuple.stats = stats;
            tuple.lfp_param = w(end);
            tuple.warning = double(~isempty(lastwarn));
            self.insert(tuple);
        end
    end
end
