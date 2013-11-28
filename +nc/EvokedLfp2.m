%{
nc.EvokedLfp2 (computed) # stimulus-evoked LFP

-> nc.EvokedLfpProfile2
-> acq.EphysStimulationLink
electrode_num       : tinyint unsigned  # electode number
---
avg_evoked_lfp      : mediumblob        # trial-average of evoked lfps
%}

classdef EvokedLfp2 < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.EvokedLfp2');
    end
    
    methods 
        function self = EvokedLfp2(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            
            % some parameters
            [start, stop] = fetchn(nc.EvokedLfpProfile & key, 'start_time', 'stop_time');
            highpass = key.min_freq;    % highpass filter cutoff
            lowpass = key.max_freq;     % lowpass filter cutoff
            
            % open file & read lfp data
            lfpFile = getLocalPath(fetch1(cont.Lfp & key, 'lfp_file'));
            br = baseReader(lfpFile, sprintf('t%d', key.electrode_num));
            lfp = br(:, 1);
            
            % extract stimulus-evoked responses
            Fs = getSamplingRate(br);
            win = (start / 1000 * Fs) : (stop / 1000 * Fs);
            switch fetch1(acq.Stimulation & key, 'exp_type')
                case 'AcuteGratingExperiment'
                    showStim = sort(double(fetchn(stimulation.StimTrialEvents & key & 'event_type = "showStimulus"', 'event_time')));
                case 'FlashingBar'
                    params = fetch1(stimulation.StimTrials & key, 'trial_params');
                    showStim = params.swapTimes(3 : 2 : end - 2);
            end
            ndx = bsxfun(@plus, getSampleIndex(br, showStim), win)';
            lfp = reshape(lfp(ndx(:), :), size(ndx));
            
            % bandpass-filter
            if highpass > 0
                [b, a] = butter(5, [highpass lowpass] / Fs * 2);
            else
                [b, a] = butter(5, lowpass / Fs * 2, 'low');
            end
            lfp = filter(b, a, lfp);

            % insert info database
            tuple = key;
            tuple.avg_evoked_lfp = mean(lfp, 2);
            self.insert(tuple);
        end
    end
end
