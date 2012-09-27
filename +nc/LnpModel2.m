% [NEW VERSION: EXPERIMENTAL]
%
% LNP model with stimulus and LFP as inputs and exponential non-linearity.
%
% The model we fit is:
%   r = exp(b*psth + c*lfp + const)
%
% where psth is a set of temporal basis functions to predict the PSTHs.
% Rather than assuming a parametric form for the tuning curve and/or
% separability of direction and time, we model the PSTH for each condition
% individually (by zeroing the basis functions of all stimuli other than
% the one shown on the given trial).
%
% bin_size is assumed to be at most 50 ms!

%{
nc.LnpModel2 (computed) # Firing rate prediction from LFP

-> nc.LnpModel2Set
-> ephys.Spikes
reg_val         : double        # small value to regularize in case of low FR
min_rate        : double        # minimum rate for conditions being used
method     : ENUM("glm", "net") # method for fitting (GLM, elastic net)
---
params = NULL   : blob          # all parameters (#conditions x #basisfun + 1)
deviance = NULL : double        # deviance of model fit
stats = NULL    : mediumblob    # stats returned by glmfit
lfp_param = NULL: double        # parameter for lfp dependence (scalar)
rates = NULL    : blob          # firing rates
lfp_data        : longblob      # filtered LFP
spike_data      : longblob      # binned spikes
warning         : boolean       # was a warning issued during fitting?
%}

% Note: the LFP from tetrode that recorded the neuron is used. I may extend
%       this to try all LFPs. In this case augment the PK by:
% electrode_num   : tinyint unsigned  # electrode number


classdef LnpModel2 < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.LnpModel2');
    end
    
    methods 
        function self = LnpModel2(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            
            % parameters
            binSize = key.bin_size;
            lowpass = 10; % cutoff (Hz)
            tol = 1e-4;
            assert(1000 / binSize >= 2 * lowpass, 'Bin size too large for lowpass cutoff. Aliasing...!');
            
            % read LFP
            tetrode = fetch1(ephys.Spikes(key), 'electrode_num');
            lfpFile = fetch1(cont.Lfp(key), 'lfp_file');
            br = baseReader(getLocalPath(lfpFile), sprintf('t%d', tetrode));
            lfp = br(:, 1);
            lfp = toMuV(br, lfp); % convert to muV
            
            % determine resampling factors
            Fs = getSamplingRate(br);
            [decp, decq] = rat(1000 / Fs / binSize, tol);
            
            % design filter for lowpass & downsampling
            N = 10;  % filter order
            bta = 5; % design parameter for Kaiser window LPF
            fc = lowpass / (Fs * decp / 2);
            L = 2 * N * decq + 1;
            filt = decp * firls(L - 1, [0 fc fc 1], [1 1 0 0]) .* kaiser(L, bta)';
            pad = round(N * decq / decp);
            
            % determine trials to use (equal number per condition)
            validTrials = validTrialsCompleteBlocks(nc.Gratings(key));

            % get spikes
            showStim = sort(fetchn(stimulation.StimTrialEvents(validTrials) & 'event_type = "showStimulus"', 'event_time'));
            spikeTimes = fetch1(ephys.Spikes(key), 'spike_times');
            spikeTimes = spikeTimes(spikeTimes > showStim(1) & spikeTimes < showStim(end) + 5000);
            
            % trials & conditions
            trials = fetch(validTrials * nc.GratingConditions, 'condition_num');
            trials = dj.struct.sort(trials, 'trial_num');
            conditions = [trials.condition_num];
            
            nSpikes = numel(spikeTimes);
            nTrials = numel(trials);
            nCond = numel(unique(conditions));
            nBins = fix(fetch1(nc.Gratings(key), 'stimulus_time') / binSize);

            trialLfp = zeros(nBins, nCond, nTrials / nCond);
            trialSpikes = zeros(nBins, nCond, nTrials / nCond);
            iSpike = 1;

            for iTrial = 1 : nTrials
                
                iBlock = ceil(iTrial / nCond);
                
                % extract lfp for this trial (samples are centered within bins)
                firstSample = getSampleIndex(br, showStim(iTrial) + binSize / 2) - pad;
                lastSample = ceil(firstSample + (nBins - 1) * decq / decp + 2 * pad);
                temp = resample(lfp(firstSample : lastSample), decp, decq, filt);
                trialLfp(:, conditions(iTrial), iBlock) = temp(N + (1 : nBins));
                
                % bin spikes
                while iSpike <= nSpikes && spikeTimes(iSpike) < showStim(iTrial)
                    iSpike = iSpike + 1;
                end
                for iBin = 1 : nBins
                    until = showStim(iTrial) + iBin * binSize;
                    curSpike = iSpike;
                    while iSpike < nSpikes && spikeTimes(iSpike) < until
                        iSpike = iSpike + 1;
                    end
                    trialSpikes(iBin, conditions(iTrial), iBlock) = iSpike - curSpike;
                end
            end
            
            % subtract stimulus-evoked LFP component
            trialLfp = bsxfun(@minus, trialLfp, mean(trialLfp, 3));
            
            opt = {0    0     'glm'; ...
                   0    0.001 'glm'; ... 
                   1    0     'glm'; ...
                   1    0.001 'glm'; ...
                   0    0     'net'; ...
                   1    0     'net'};
            for i = 1 : size(opt, 1)
                
                minRate = opt{i, 1};
                regVal = opt{i, 2};
                method = opt{i, 3};
                fprintf('  minRate = %f | regVal = %f | method = %s\n', minRate, regVal, method)
                
                % determine conditions satisfying min rate constraint
                rates = mean(mean(trialSpikes, 1), 3) / binSize * 1000;
                cond = find(rates >= minRate);
                
                % reset warnings
                lastwarn('');
                
                if ~isempty(cond)
                    X = [self.stimMatrix(key, numel(cond)), reshape(trialLfp(:, cond, :), [], 1)];
                    y = reshape(trialSpikes(:, cond, :), [], 1) + regVal;
                    switch method
                        case 'glm'
                            [w, dev, stats] = glmfit(X, y, 'poisson', 'constant', 'off');
                        case 'net'
                            [w, stats] = lassoglm(X, y, 'poisson', 'cv', 10, 'lambda', 10.^(-6 : 0), 'alpha', 0.8, 'standardize', false);
                            stats.w = w;
                            ndx = stats.IndexMinDeviance;
                            dev = stats.Deviance(ndx);
                            w = [stats.Intercept(ndx); w(:, ndx)];
                    end
                else
                    w = NaN;
                    dev = NaN;
                    stats = NaN;
                end
                
                % insert into db
                key.reg_val = regVal;
                key.min_rate = minRate;
                key.method = method;
                tuple = key;
                tuple.params = w;
                tuple.deviance = dev;
                tuple.stats = stats;
                tuple.lfp_param = w(end);
                tuple.rates = rates(cond);
                tuple.lfp_data = trialLfp(:, cond, :);
                tuple.spike_data = trialSpikes(:, cond, :);
                tuple.warning = double(~isempty(lastwarn));
                self.insert(tuple);
                
                % fit GLM for each condition separately
                if ismember(i, [3 5])
                    fprintf('  condition')
                    for iCond = cond
                        fprintf(' %d', iCond)
                        lastwarn('');
                        X = [self.stimMatrix(key, 1), reshape(trialLfp(:, iCond, :), [], 1)];
                        y = reshape(trialSpikes(:, iCond, :), [], 1);
                        switch method
                            case 'glm'
                                [w, dev, stats] = glmfit(X, y, 'poisson', 'constant', 'off');
                            case 'net'
                                % have to remove the DC component from X
                                % since lassoglm adds a constant term
                                [w, stats] = lassoglm(X(:, 2:end), y, 'poisson', 'cv', 10, 'lambda', 10.^(-6 : 0), 'alpha', 0.8, 'standardize', false);
                                stats.w = w;
                                ndx = stats.IndexMinDeviance;
                                dev = stats.Deviance(ndx);
                                w = [stats.Intercept(ndx); w(:, ndx)];
                        end
                        tuple = key;
                        tuple.condition_num = iCond;
                        tuple.params = w;
                        tuple.deviance = dev;
                        tuple.stats = stats;
                        tuple.lfp_param = w(end);
                        tuple.rate = rates(iCond);
                        tuple.lfp_data = permute(trialLfp(:, iCond, :), [1 3 2]);
                        tuple.spike_data = permute(trialSpikes(:, iCond, :), [1 3 2]);
                        tuple.warning = double(~isempty(lastwarn));
                        insert(nc.LnpModel2Cond, tuple);
                    end
                    fprintf('\n')
                end
            end
        end
        
        function X = designMatrix(self)
            error('not correct. needs to be fixed!')
            assert(count(self) == 1, 'Relvar must be scalar!')
            stim = nc.LnpModel.stimMatrix(fetch(self));
            lfp = fetch1(self, 'lfp_data');
            X = [stim, lfp(:)];
        end
    end
    
    methods (Static)
        function S = stimMatrix(key, nCond)
            % Create stimulus part of the design matrix.
            %   We use 10 basis functions (1st one is DC) for each stimulus
            %   condition. The basis function are obtained by doing PCA on
            %   the PSTHs (see nc.PsthBasis)
            
            validTrials = validTrialsCompleteBlocks(nc.Gratings(key));
            trialsPerBlock = fix(count(validTrials) / count(nc.GratingConditions(key)));
            nBins = fix(fetch1(nc.Gratings(key), 'stimulus_time') / key.bin_size);
            nBasisFun = 10;
            psth = fetch1(nc.PsthBasis(key), 'psth_eigenvectors');
            psth = [ones(nBins, 1), psth(1 : nBins, 1 : nBasisFun - 1)];
            S = kron(repmat(eye(nCond), trialsPerBlock, 1), psth);
        end
    end
end
