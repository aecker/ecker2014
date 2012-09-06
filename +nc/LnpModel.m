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
nc.LnpModel (computed) # Firing rate prediction from LFP

-> nc.LnpModelSet
-> ephys.Spikes
---
params          : blob      # all parameters (#conditions x #basisfun + 1)
lfp_param       : double    # parameter for lfp dependence (scalar)
lfp_data        : longblob  # filtered LFP
spike_data      : longblob  # binned spikes
%}

% Note: the LFP from tetrode that recorded the neuron is used. I may extend
%       this to try all LFPs. In this case augment the PK by:
% electrode_num   : tinyint unsigned  # electrode number


classdef LnpModel < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.LnpModel');
    end
    
    methods 
        function self = LnpModel(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            
            % parameters
            lowpass = 10; % cutoff (Hz)
            tol = 1e-4;
            assert(1000 / key.bin_size > 2 * lowpass, 'Bin size too large for lowpass cutoff. Aliasing...!');
            
            % read LFP
            tetrode = fetch1(ephys.Spikes(key), 'electrode_num');
            lfpFile = fetch1(cont.Lfp(key), 'lfp_file');
            br = baseReader(getLocalPath(lfpFile), sprintf('t%d', tetrode));
            lfp = br(:, 1);
            
            % determine resampling factors
            Fs = getSamplingRate(br);
            [decp, decq] = rat(1000 / Fs / key.bin_size, tol);
            
            % design filter for lowpass & downsampling
            N = 10;  % filter order
            bta = 5; % design parameter for Kaiser window LPF
            fc = lowpass / (Fs * decp / 2);
            L = 2 * N * decq + 1;
            filt = decp * firls(L - 1, [0 fc fc 1], [1 1 0 0]) .* kaiser(L, bta)';
            pad = round(N * decq / decp);
            
            % get spikes
            showStim = sort(fetchn(stimulation.StimTrialEvents(key) & 'event_type = "showStimulus"', 'event_time'));
            endStim = sort(fetchn(stimulation.StimTrialEvents(key) & 'event_type = "endStimulus"', 'event_time'));
            spikeTimes = fetch1(ephys.Spikes(key), 'spike_times');
            spikeTimes = spikeTimes(spikeTimes > showStim(1) & spikeTimes < endStim(end) + 5000);
            nSpikes = numel(spikeTimes);
            
            % trials & conditions
            trials = fetch(nc.GratingTrials(key) * nc.GratingConditions, 'direction');
            trials = dj.struct.sort(trials, 'trial_num');
            nTrials = numel(trials);
            conditions = [trials.condition_num];
            nCond = numel(unique(conditions));

            nBins = fix(fetch1(nc.Gratings(key), 'stimulus_time') / key.bin_size);
            binSize = key.bin_size;
            trialLfp = zeros(nBins, nTrials);
            trialSpikes = zeros(nBins, nTrials);
            iSpike = 1;

            % TEMP
            ppsth = zeros(nBins, 16);
            
            for iTrial = 1 : nTrials
    
                % extract lfp for this trial (samples are centered within bins)
                firstSample = getSampleIndex(br, showStim(iTrial) + binSize / 2) - pad;
                lastSample = ceil(firstSample + (nBins - 1) * decq / decp + 2 * pad);
                temp = resample(lfp(firstSample : lastSample), decp, decq, filt);
                trialLfp(:, iTrial) = temp(N + (1 : nBins));
                
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
                    trialSpikes(iBin, iTrial) = iSpike - curSpike;
                    ppsth(iBin, conditions(iTrial)) = ppsth(iBin, conditions(iTrial)) + iSpike - curSpike;
                end
            end
            
            % subtract stimulus-evoked LFP component
            for i = 1 : nCond
                ndx = conditions == i;
                trialLfp(:, ndx) = bsxfun(@minus, trialLfp(:, ndx), mean(trialLfp(:, ndx), 2));
            end
            
            % FIT GLM
            X = [self.stimMatrix(key), trialLfp(:)];
            w = glmfit(X, trialSpikes(:), 'poisson', 'constant', 'off');
            
            % insert into db
            tuple = key;
            tuple.params = w;
            tuple.lfp_param = w(end);
            tuple.lfp_data = trialLfp;
            tuple.spike_data = trialSpikes;
            self.insert(tuple);
        end
        
        function X = designMatrix(self)
            assert(count(self) == 1, 'Relvar must be scalar!')
            stim = nc.LnpModel.stimMatrix(fetch(self));
            lfp = fetch1(self, 'lfp_data');
            X = [stim, lfp(:)];
        end
    end
    
    methods (Access = private, Static)
        function stim = stimMatrix(key)
            % trials & conditions
            trials = fetch(nc.GratingTrials(key) * nc.GratingConditions, 'direction');
            trials = dj.struct.sort(trials, 'trial_num');
            nTrials = numel(trials);
            conditions = [trials.condition_num];
            nCond = numel(unique(conditions));
            nBins = fix(fetch1(nc.Gratings(key), 'stimulus_time') / key.bin_size);
            
            % create stimulus (PSTH) basis function matrix
            nBasisFun = 10;
            psth = fetch1(nc.PsthBasis(key), 'psth_eigenvectors');
            psth = [ones(nBins, 1), psth(1 : nBins, 1 : nBasisFun - 1)];
            stim = zeros(nTrials * nBins, nBasisFun * nCond);
            for iTrial = 1 : nTrials
                iRows = nBins * (iTrial - 1) + (1 : nBins);
                iCols = nBasisFun * (conditions(iTrial) - 1) + (1 : nBasisFun);
                stim(iRows, iCols) = psth;
            end            
        end
    end
end
