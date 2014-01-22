%{
acq.SessionsIgnore (manual)       # sessions to ignore
->acq.Sessions
%}

classdef SessionsIgnore < dj.Relvar
    properties(Constant)
        table = dj.Table('acq.SessionsIgnore');
    end
    
    methods 
        function self = SessionsIgnore(varargin)
            self.restrict(varargin{:})
        end
    end
end
