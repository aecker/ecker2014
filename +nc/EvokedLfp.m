%{
nc.EvokedLfp (computed) # stimulus-evoked LFP

-> nc.EvokedLfpProfile
-> acq.EphysStimulationLink
electrode_num       : tinyint unsigned  # electode number
---
evoked_lfp          : longblob          # stimulus-evoked lfps
avg_evoked_lfp      : mediumblob        # trial-average of evoked lfps
%}

classdef EvokedLfp < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.EvokedLfp');
    end
    
    methods 
        function self = EvokedLfp(varargin)
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
            showStim = sort(fetchn(stimulation.StimTrialEvents & key & 'event_type = "showStimulus"', 'event_time'));
            ndx = bsxfun(@plus, getSampleIndex(br, showStim), win)';
            lfp = reshape(lfp(ndx(:), :), size(ndx));
            
            % bandpass-filter and resample
            [p, q] = rat(2 * lowpass / Fs);
            lfp = resample(lfp, p, q);
            [b, a] = butter(5, highpass / lowpass, 'high');
            lfp = filtfilt(b, a, lfp);

            % insert info database
            tuple = key;
            tuple.evoked_lfp = lfp;
            tuple.avg_evoked_lfp = mean(lfp, 2);
            self.insert(tuple);
        end
    end
end
