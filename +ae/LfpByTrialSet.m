%{
ae.LfpByTrialSet (computed) # LFP organized by trials

-> stimulation.StimTrialGroup
-> ae.LfpFilter
-> cont.Lfp
---
lfp_sampling_rate                   : double        # sampling rate
pre_stim_time                       : float         # start of window (ms before stim onset)
lfpbytrialset_ts=CURRENT_TIMESTAMP  : timestamp     # automatic timestamp. Do not edit
%}

classdef LfpByTrialSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ae.LfpByTrialSet');
        popRel = (acq.StimulationSyncDiode & (ae.ProjectsStimulation * ae.LfpByTrialProjects)) ...
            * cont.Lfp * stimulation.StimTrialGroup * ae.LfpFilter;
    end
    
    methods 
        function self = LfpByTrialSet(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            
            % open LFP file
            lfpFile = getLocalPath(fetch1(cont.Lfp(key), 'lfp_file'));
            br = baseReader(lfpFile);
            tuple = key;
            tuple.lfp_sampling_rate = getSamplingRate(br);
            tuple.pre_stim_time = 1000;
            insert(self, tuple);
            
            % setup filtering
            [fmin, fmax, w] = fetch1(ae.LfpFilter(key), 'min_freq', 'max_freq', 'dont_care_width');
            if fmin > 0 && fmax > 0
                filter = filterFactory.createBandpass(fmin - w, fmin, fmax, fmax + w, tuple.lfp_sampling_rate);
            elseif fmin > 0
                filter = filterFactory.createHighpass(fmin - w, fmin, tuple.lfp_sampling_rate);
            elseif fmax > 0
                filter = filterFactory.createLowpass(fmax, fmax + w, tuple.lfp_sampling_rate);
            else
                filter = [];
            end
            
            % process electrodes & trials
            channelNames = getChannelNames(br);
            electrodes = regexp(channelNames, '\w(\d+)*', 'tokens', 'once');
            electrodes = cellfun(@(x) str2double(x{1}), electrodes(:));
            close(br);
            for i = 1:numel(electrodes)
                fprintf('Electrode %d\n', electrodes(i))
                br = baseReader(lfpFile, channelNames{i});
                if ~isempty(filter)
                    reader = filteredReader(br, filter);
                else
                    reader = br;
                end
                trials = fetch(cont.Lfp(key) * (stimulation.StimTrials(key) ...
                    & stimulation.StimTrialEvents('event_type = "showStimulus"')) ...
                    * ae.LfpFilter(key));
                for trial = trials'
                    trial.electrode_num = electrodes(i);
                    makeTuples(ae.LfpByTrial, trial, reader);
                end
                close(br);
            end
        end
    end
end
