%{
stimulation.StimTrialEvents (imported) # Events for trials

-> stimulation.StimTrials
event_type      : enum("startTrial","showFixSpot","acquireFixation","showStimulus","showSubStimulus","response","reward","fixationTimeoutAbort","endSubStimulus","eyeAbort","noResponse","leverAbort","prematureAbort","clearScreen","saccade","endStimulus","pause","startTrialSound","eyeAbortSound","noResponseSound","leverAbortSound","rewardSound","prematureAbortSound","correctResponseSound","incorrectResponseSound","userInteraction","emParams","sound","eot","endFixSpot","endTrial","endSession","netSyncFlash","startCoherent","endCoherent") # Type of stimulation event
event_time      : bigint unsigned       # Time of stimulation event (in ms relative to start of session)
---
event_info=null             : blob                          # Miscellaneous information attached to stimulation event (in ms)
stimtrialevents_ts=CURRENT_TIMESTAMP: timestamp             # automatic timestamp. Do not edit
%}

classdef StimTrialEvents < dj.Relvar
    properties(Constant)
        table = dj.Table('stimulation.StimTrialEvents');
    end
    
    methods 
        function self = StimTrialEvents(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key, events )
            tuple = key;
            for i = 1:length(events.types)
                tuple.event_type = events.types{i}; % Type of stimulation event
                tuple.event_time = events.times(i);
                tuple.event_info = events.info{i};
                
                if isnan(tuple.event_time) || tuple.event_time < 0
                    % (a) Time was not recorded
                    % (b) In some old sessions sounds got timestamped as
                    % zero, which translated into negative times after
                    % synchronization
                    continue;
                end
                
                insert(this,tuple);
            end
        end
    end
end
