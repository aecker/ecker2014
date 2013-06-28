%{
nc.EvokedLfpProfile (computed) # stimulus-evoked LFP profile over layers

-> acq.Sessions
-> nc.EvokedLfpParams
---
start_time          : double    # start time of window relative to stim onset
stop_time           : double    # stop time
lfp_sampling_rate   : double    # sampling rate
%}

classdef EvokedLfpProfile < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.EvokedLfpProfile');
        popRel = (acq.Sessions * nc.EvokedLfpParams & acq.Stimulation) ...
            - ((acq.Stimulation * acq.EphysStimulationLink ...
                * ae.ProjectsStimulation * nc.EvokedLfpParams ...
                & 'project_name = "NoiseCorrAnesthesia"') - (cont.Lfp & stimulation.StimTrialGroup));
    end
    
    methods 
        function self = EvokedLfpProfile(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            
            % sampling rate
            lfpFile = getLocalPath(fetch1(cont.Lfp & key, 'lfp_file', 'LIMIT 1'));
            br = baseReader(lfpFile);
            Fs = getSamplingRate(br);
            
            % some parameters
            tuple = key;
            tuple.start_time = -1000;
            tuple.stop_time = 3000;
            tuple.lfp_sampling_rate = Fs;
            
            rel = cont.Lfp * acq.EphysStimulationLink * acq.Stimulation * ...
                nc.EvokedLfpParams & ae.ProjectsStimulation & key;
            stimKeys = fetch(rel);
            nStim = count(rel);
            
            % select all electrodes that were available in all recordings
            tetrodes = false(nStim, 24);
            for iStim = 1 : nStim
                tetrodes(iStim, fetchn(detect.Electrodes & stimKeys(iStim), 'electrode_num')) = true;
            end
            tetrodes = find(all(tetrodes, 1));
            nTet = numel(tetrodes);

            % insert parent key and link tables
            self.insert(tuple);
            for tet = tetrodes
                k = key;
                k.electrode_num = tet;
                insert(nc.EvokedLfpElectrodes, k);
            end
            
            % extract evoked LFPs
            for iStim = 1 : nStim
                stimKey = stimKeys(iStim);
                insert(nc.EvokedLfpStims, stimKey);
                for iTet = 1 : nTet
                    k = stimKey;
                    k.electrode_num = tetrodes(iTet);
                    makeTuples(nc.EvokedLfp, k);
                end
                disp(iStim)
            end
        end
    end
end
