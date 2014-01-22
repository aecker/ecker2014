%{
stimulation.StimTrialGroup (imported) # Set of imported trials

-> acq.StimulationSync
---
stim_constants                     : longblob               # A structure with all the stimulation constants
stimtrialgroup_ts=CURRENT_TIMESTAMP: timestamp              # automatic timestamp. Do not edit
%}
classdef StimTrialGroup < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('stimulation.StimTrialGroup');
        popRel = acq.StimulationSync;
    end
    
    methods 
        function self = StimTrialGroup(varargin)
            self.restrict(varargin{:})
        end
        
        function val = getConstant(self, field, varargin)
            constants = fetchn(self, 'stim_constants');
            val = cellfun(@(x) x.(field), constants, varargin{:});
        end
    end
    
    methods (Access=protected)        
        function self = makeTuples(self, key)
            tuple = key;
            
            try
                stim = getStim(acq.Stimulation(key),'Synced');
            catch %#ok
                stim = getStim(acq.Stimulation(key),'Synched');
            end
            tuple.stim_constants = stim.params.constants;
            insert(self, tuple);

            % Insert conditions
            makeTuples(stimulation.StimConditions, key, stim);
            % Insert trials
            makeTuples(stimulation.StimTrials, key, stim);

        end
    end
end
