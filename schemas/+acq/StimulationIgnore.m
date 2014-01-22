%{
acq.StimulationIgnore (manual)       # stimulation sessions to ignore
->acq.Stimulation
%}

classdef StimulationIgnore < dj.Relvar
    properties(Constant)
        table = dj.Table('acq.StimulationIgnore');
    end
    
    methods 
        function self = StimulationIgnore(varargin)
            self.restrict(varargin{:})
        end
    end
end
