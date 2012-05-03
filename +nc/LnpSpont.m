%{
nc.LnpSpont (computed) # Spontaneous firing rate prediction from LFP

-> nc.LnpSpontSet
-> ephys.Spikes
---
rate_param      : double            # parameter for spontaneous firing rate
lfp_param       : double            # parameter for lfp dependence
perc_var        : float             # percent variance explained by LFP
%}

% NOTE: LFP from tetrode that recorded the neuron is used. I may extend
%       this to try all LFPs. In this case augment the PK by:
% electrode_num   : tinyint unsigned  # electrode number

% The model we fit is:
%   r = exp(b*lfp + c)

classdef LnpSpont < dj.Relvar
    properties (Constant)
        table = dj.Table('nc.LnpSpont');
    end
    
    methods 
        function self = LnpSpont(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            
            % parameters
            win = 50;
            smoothing = 3;
            postStim = 500;
            
            % read LFP
            tetrode = fetch1(ephys.Spikes(key), 'electrode_num');
            lfpFile = fetch1(cont.Lfp(key), 'lfp_file');
            br = baseReader(getLocalPath(lfpFile), sprintf('t%d', tetrode));
            lfp = br(:, 1);
            
            % downsample and smooth
            Fs = getSamplingRate(br);
            decimation = round(Fs / 1000 * win);
            lfp = resample(lfp, 1, decimation, ones(decimation, 1) / decimation);
            lfp = filter(ones(smoothing, 1) / smoothing, 1, lfp);
            lfp = lfp(ceil(smoothing / 2) : end);
            tLfp = br(1, 't') + (0 : numel(lfp)) / Fs * 1000 * decimation;
            
            % determine segments of spontaneous activity
            showStim = sort(fetchn(stimulation.StimTrialEvents(key) & 'event_type = "showStimulus"', 'event_time'));
            endStim = sort(fetchn(stimulation.StimTrialEvents(key) & 'event_type = "endStimulus"', 'event_time'));
            spikeTimes = fetch1(ephys.Spikes(key), 'spike_times');
            spikeTimes = spikeTimes(spikeTimes > endStim(1) & spikeTimes < showStim(end));
            nTrials = numel(showStim);
            use = false(size(lfp));
            spikeCounts = zeros(size(lfp));
            nLfp = numel(tLfp);
            nSpikes = numel(spikeTimes);
            iLfp = 1;
            iSpike = 1;
            for iTrial = 1 : nTrials - 1
                while iLfp < nLfp && tLfp(iLfp) < endStim(iTrial) + postStim
                    iLfp = iLfp + 1;
                end
                while iSpike < nSpikes && spikeTimes(iSpike) < tLfp(iLfp)
                    iSpike = iSpike + 1;
                end
                while iLfp < nLfp && tLfp(iLfp + 1) < showStim(iTrial + 1)
                    use(iLfp) = true;
                    curSpike = iSpike;
                    while iSpike <= nSpikes && spikeTimes(iSpike) < tLfp(iLfp + 1)
                        iSpike = iSpike + 1;
                    end
                    spikeCounts(iLfp) = iSpike - curSpike;
                    iLfp = iLfp + 1;
                end
            end
            lfp = lfp(use);
            spikeCounts = spikeCounts(use);
            
            % Fit GLM
            b = glmfit(lfp, spikeCounts, 'poisson');
            
            % Insert into db
            tuple = key;
            tuple.rate_param = b(1);
            tuple.lfp_param = b(2);
            tuple.perc_var = var(glmval(b, lfp, 'log')) / var(spikeCounts);
            self.insert(tuple);
        end
    end
end
