%{
acq.Stimulation (manual)       # visual stimulations

->acq.Sessions
stim_start_time         : bigint        # timestamp for stimulation start
---
stim_stop_time = NULL   : bigint        # end of stimulation timestamp
stim_path               : varchar(255)  # path to the stimulation data
exp_type                : varchar(255)  # type of experiment
total_trials = NULL     : int unsigned  # total number of trials completed
correct_trials = NULL   : int unsigned  # number of correct trials
incorrect_trials = NULL : int unsigned  # number of incorrect trials
%}

classdef Stimulation < dj.Relvar
    properties(Constant)
        table = dj.Table('acq.Stimulation');
    end
    
    methods 
        function self = Stimulation(varargin)
            self.restrict(varargin{:})
        end
        
        function fileName = getFileName(self, varargin)
            % Get name of stimulation file for tuple in relvar
            %   fileName = getStimFile(self, [variant]) returns the file
            %   name matching the tuple in self. If the string variant is
            %   passed as second input it is appended at the end of the
            %   file name (e.g. 'Synched').
            [stimPath, expType] = fetch1(self, 'stim_path', 'exp_type');
            switch(expType)
                case 'MouseMultiDim'
                    expType = 'MultDimExperiment';
                case 'MouseBar'
                    expType = 'BarMappingExperiment';
                case 'WhiteNoiseOrientationDetection'
                    expType = 'WNOriDetectExperiment';
                otherwise
            end
            fileName = getLocalPath([stimPath '/' expType varargin{:} '.mat']);
        end
        
        function [stim, fileName] = getStim(self, varargin)
            % Load stimulation file for tuple in relvar
            %   [stim, fileName] = getStimFile(self, [variant]) returns the
            %   stimulation structure matching the tuple in self. If the
            %   string variant is passed as second input it is appended at
            %   the end of the file name (e.g. 'Synched').
            fileName = getFileName(self, varargin{:});
            stim = getfield(load(fileName), 'stim'); %#ok
        end
    end
end
