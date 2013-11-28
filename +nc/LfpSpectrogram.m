%{
nc.LfpSpectrogram (computed) # LFP spectrogram

-> cont.Lfp
-> nc.Gratings
-> nc.LfpSpectrogramParams
---
-> ephys.SpikeSet
frequencies         : longblob      # frequencies
spectrogram         : longblob      # spectrogram
%}

classdef LfpSpectrogram < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.LfpSpectrogram');
        popRel = cont.Lfp * nc.Gratings * nc.LfpSpectrogramParams ...
            & (nc.Anesthesia * nc.AnalysisStims & 'state = "anesthetized"') ...
            & (ephys.SpikeSet & 'detect_method_num = 4 AND sort_method_num = 5');
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            
            key.detect_method_num = 4;
            key.sort_method_num = 5;
            
            lfpFile = getLocalPath(fetch1(cont.Lfp & key, 'lfp_file'));
            br = baseReader(lfpFile, 't*');
            tets = cellfun(@(x) sscanf(x, 't%d'), getChannelNames(br));
            Fs = getSamplingRate(br);
            
            % determine tetrodes with single units
            suaTet = unique(fetchn(ephys.Spikes & key, 'electrode_num'));
            
            % determine time range of experiment
            showStim = double(sort(fetchn(nc.Gratings * stimulation.StimTrialEvents & key ...
                & 'event_type = "showStimulus"', 'event_time')));
            first = getSampleIndex(br, showStim(1));
            last = getSampleIndex(br, showStim(end) + mean(diff(showStim)));
            win = 2 * fix((last - first) / key.num_blocks / 2);
            
            % read LFP and compute spectrogram
            lfp = br(first : last, :);
            if key.all_tt
                lfp = mean(lfp, 2);
            else
                lfp = mean(lfp(:, ismember(tets, suaTet)), 2);
            end
            S = spectrogram(lfp, win);
            
            tuple = key;
            tuple.frequencies = linspace(0, Fs / 2, size(S, 1));
            tuple.spectrogram = S;
            self.insert(tuple)
        end
    end
end
