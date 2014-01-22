%{
acq.BehaviorTracesIgnore (manual)       # behavior traces to ignore
->acq.BehaviorTraces
%}

classdef BehaviorTracesIgnore < dj.Relvar
    properties(Constant)
        table = dj.Table('acq.BehaviorTracesIgnore');
    end
    
    methods 
        function self = BehaviorTracesIgnore(varargin)
            self.restrict(varargin{:})
        end
    end
end
