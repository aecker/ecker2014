%{
acq.BehaviorTraces (manual) # behavioral data recordings

-> acq.Stimulation
beh_start_time       : bigint        # timestamp for recordng start
---
beh_stop_time = NULL : bigint        # end of recording timestamp
beh_path             : varchar(255)  # path to the behavioral data
beh_traces_type      : enum('analog','optical_fpga')  # type of recording
%}

classdef BehaviorTraces < dj.Relvar
    properties(Constant)
        table = dj.Table('acq.BehaviorTraces');
    end
    
    methods 
        function self = BehaviorTraces(varargin)
            self.restrict(varargin{:})
        end
        
        function fn = getFileName(self)
            % Return name of data file matching the tuple in relvar self.
            %   fn = getFileName(self)
            behPath = fetch1(acq.Sessions * self, 'beh_path');
            fn = findFile(RawPathMap, behPath);
        end
        
        function br = getFile(self, varargin)
            % Open a reader for the file matching the tuple in relvar self.
            %   br = getFile(self)
            br = baseReader(getFileName(self), varargin{:});
        end
        
        function time = getHardwareStartTime(self)
            % Get the hardware start time for the tuple in relvar
            %   time = getHardwareStartTime(self)
            cond = sprintf('ABS(timestamper_time - %ld) < 3000', fetch1(self, 'beh_start_time'));
%             ts = fetch(acq.SessionTimestamps(cond) & acq.TimestampSources('source = "Behavior"') & (acq.Sessions * self), '*');
%             time = counterToTime(ts);
            rel = acq.SessionTimestamps(cond) & acq.TimestampSources('source = "Behavior"') & (acq.Sessions * self);
            time = acq.SessionTimestamps.getRealTimes(rel);
        end
    end
end
