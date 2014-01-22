%{
acq.EphysIgnore (manual)       # ephys recording to ignore
->acq.Ephys
%}

classdef EphysIgnore < dj.Relvar
    properties(Constant)
        table = dj.Table('acq.EphysIgnore');
    end
    
    methods 
        function self = EphysIgnore(varargin)
            self.restrict(varargin{:})
        end
    end
end
