% LNP model with stimulus and LFP as inputs and exponential non-linearity.
%
% The model we fit is:
%   r = exp(a*psi + b*psth + c*lfp + const)
%
% where psi = [cos(theta), sin(theta), cos(2*theta), sin(2*theta)] is the
% tuning curve and psth the temporal structure of the response (which are
% assumed to factor since they're additive in the exp).
%
% bin_size is assumed to be at most 50 ms!

%{
nc.LnpModel (computed) # Firing rate prediction from LFP

-> nc.LnpModelSet
-> ephys.Spikes
---
tuning_params   : blob      # parameters for tuning curve (4-by-1)
psth_params     : blob      # parameters for PSTH (k-by-1)
lfp_param       : double    # parameter for lfp dependence (scalar)
const_param     : double    # constant parameter
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
            lowpass = [5 10]; % cutoff (Hz)
            tol = 1e-5;
            assert(1000 / key.bin_size > 2 * lowpass(2), 'Bin size too large for lowpass cutoff. Aliasing...!');
            
            % read LFP
            tetrode = fetch1(ephys.Spikes(key), 'electrode_num');
            lfpFile = fetch1(cont.Lfp(key), 'lfp_file');
            br = baseReader(getLocalPath(lfpFile), sprintf('t%d', tetrode));
            lfp = br(:, 1);
            
            % design filter for lowpass & downsampling
            Fs = getSamplingRate(br);
            decimation = Fs / 1000 * key.bin_size;
            assert(rem(decimation + tol, 1) < 2 * tol, 'Bin size must be multiple of sampling period!')
            decimation = round(decimation);
            params = firpmord(lowpass, [1 0], [0.1 0.01], Fs, 'cell');
            filt = firpm(params{:});
            delay = numel(filt) / 2;
            pad = ceil(ceil(delay / decimation) * decimation - decimation / 2);

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
                firstSample = getSampleIndex(br, showStim(iTrial)) - pad;
                lastSample = firstSample + nBins * decimation + 2 * pad;
                temp = resample(lfp(firstSample : lastSample + 1), 1, decimation, filt);
                trialLfp(:, iTrial) = temp(ceil(pad / decimation) + (1 : nBins));
                
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
            
            % create stimulus matrix
            direction = [trials.direction] / 180 * pi;
            stim = repmat(direction, nBins, 1);
            stim = [cos(stim(:)), sin(stim(:)), cos(2 * stim(:)), sin(2 * stim(:))];
            
            % create PSTH basis function matrix
            nBasisFunc = 20;
            psth = fetch1(nc.PsthBasis('use_log = false'), 'psth_eigenvectors');
            psth = psth(1 : nBins, 1 : nBasisFunc);
            psth = repmat(psth, nTrials, 1);
            
            % fit GLM
            X = [stim, psth, trialLfp(:)];
            w = glmfit(X, trialSpikes(:), 'poisson');
            
            % insert into db
            tuple = key;
            tuple.tuning_params = w(2:5);
            tuple.psth_params = w(5 + (1 : nBasisFunc));
            tuple.lfp_param = w(end);
            tuple.const_param = w(1);
            tuple.lfp_data = trialLfp;
            tuple.spike_data = trialSpikes;
            self.insert(tuple);
        end
    end
end
