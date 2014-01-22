%{
acq.SessionsCleanup (computed) # cleanup before processing can be done

->acq.Sessions
---
%}

classdef SessionsCleanup < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('acq.SessionsCleanup');
        popRel = acq.Sessions - acq.SessionsIgnore;
    end
    
    methods
        function self = SessionsCleanup(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access=protected)        
        function makeTuples(self, key)
            if count(acq.Sessions(key) & 'recording_software = "Acquisition2.0"')
                cleanup(key);
            end
            insert(self, key);
        end
    end
end
