%{
stimulation.StimConditions (imported) # Handle for trials of a particular condition

-> stimulation.StimTrialGroup
condition_num   : int unsigned          # Condition number
---
condition_info=null         : longblob                      # Matlab structure with information on this condition
stimconditions_ts=CURRENT_TIMESTAMP: timestamp              # automatic timestamp. Do not edit
%}

classdef StimConditions < dj.Relvar
    properties(Constant)
        table = dj.Table('stimulation.StimConditions');
    end
    
    methods 
        function self = StimConditions(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples( this, key, stim )
            % Called once of each stimulation
            %   Create the conditions entry for each type
            %   Call makeTuples on StimValidTrials
            %     This will create all the events for that trial
            
            tuple = key;
            
            for cond = 1:length(stim.params.conditions)
                tuple.condition_num = cond; % Condition number
                tuple.condition_info = stim.params.conditions(cond);
                
                insert(this,tuple);
            end
        end
        
        function val = getConditionParam(self, field, varargin)
            assert(count(stimulation.StimTrialGroup & self) == 1, 'Conditions must be from the same session!')
            % try conditions
            conditions = fetchn(self, 'condition_info', 'ORDER BY condition_num');
            if isfield(conditions{1}, field)
                val = cellfun(@(x) x.(field), conditions, varargin{:});
            else % try constants
                val = repmat(getConstant(stimulation.StimTrialGroup & self, field), count(self), 1);
            end
        end
    end
end
