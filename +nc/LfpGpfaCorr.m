%{
nc.LfpGpfaCorr (imported) # LFP/GPFA correlation

-> ae.Lfp
-> nc.Gratings
-> ae.SpikesByTrialSet
-> nc.DataTransforms
-> nc.GpfaParams
---
lfp             : longblob  # LFP with stimulus-evoked component subtracted
lfp_trial       : longblob  # LFP with trial-average subtracted
gpfa_x          : longblob  # latent factor of GPFA model
gpfa_x_trial    : longblob  # latent factor of GPFA trial-average subtracted
corr            : double    # correlation between stimulus-subtracted LFP and GPFA
p               : double    # p value
corr_trial      : double    # correlation between trial-average-subtracted
p_trial         : double    # p value
%}

classdef LfpGpfaCorr < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.LfpGpfaCorr');
        popRel = (ae.Lfp * nc.Gratings * ae.SpikesByTrialSet * nc.DataTransforms * nc.GpfaParams) ...
            & nc.GpfaModelSet & 'kfold_cv = 1 AND max_latent_dim = 1';
    end
    
    methods
        function self = LfpGpfaCorr(varargin)
            self.restrict(varargin{:})
        end
    end

    methods(Access = protected)
        function makeTuples(self, key)
            
            modelKey = key;
            modelKey.latent_dim = 1;
            
            stimTime = fetch1(nc.Gratings & key, 'stimulus_time');
            binSize = fetch1(nc.GpfaParams * nc.GpfaModelSet & modelKey, 'bin_size', 1);
            Fs = 1000 / binSize;
            nBins = round(stimTime / binSize);
            
            % extract LFP
            [lfp, Flfp, t0] = fetch1(ae.Lfp & key, 'lfp', 'lfp_sampling_rate', 'lfp_t0');
            [p, q] = rat(Fs / Flfp, 1e-3);
            assert(p < 100 && q < 100, 'Problem with resampling LFP!')
            lfp = resample(lfp, p, q);
            
            cond = fetchn(nc.GpfaModel & modelKey, 'condition_num');
            allTrials = sort(fetchn(nc.GratingTrials * nc.GpfaModel & modelKey, 'trial_num'));
            nCond = numel(cond);
            nTrials = numel(allTrials);
            X = zeros(nBins, nTrials);
            Z = zeros(nBins, nTrials);
            for iCond = 1 : nCond
                condKey = modelKey;
                condKey.condition_num = cond(iCond);
                trials = sort(fetchn(nc.GratingTrials & condKey, 'trial_num'));
                [~, trials] = ismember(trials, allTrials);
                
                % remove stimulus-evoked component from LFP
                showStims = sort(fetchn(stimulation.StimTrialEvents * nc.GratingTrials...
                    & condKey & 'event_type = "showStimulus"', 'event_time'));
                ndx = bsxfun(@plus, round((showStims - t0) * Fs / 1000), 1 : nBins)';
                Zi = lfp(ndx);
                Zi = bsxfun(@minus, Zi, mean(Zi, 2));
                Z(:, trials) = Zi;

                % estimate latent factor
                [model, Y] = fetch1(nc.GpfaModelSet * nc.GpfaModel & condKey, 'model', 'transformed_data');
                model = GPFA(model);
                Xi = model.estX(Y);
                Xi = Xi * sign(median(model.C));   % flip sign?
                X(:, trials) = Xi;
            end
            
            % subtract trial averages
            Zt = bsxfun(@minus, Z, mean(Z, 1));
            Xt = bsxfun(@minus, X, mean(X, 1));
            
            % insert into database
            tuple = key;
            tuple.lfp = Z;
            tuple.lfp_trial = Zt;
            tuple.gpfa_x = X;
            tuple.gpfa_x_trial = Xt;
            [rho, p] = corr(X(:), Z(:));
            tuple.corr = rho;
            tuple.p = p;
            [rho, p] = corr(Xt(:), Zt(:));
            tuple.corr_trial = rho;
            tuple.p_trial = p;
            self.insert(tuple);
        end
    end
end
