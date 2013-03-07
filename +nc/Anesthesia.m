%{
nc.Anesthesia (manual) # Subject to brain state mapping

-> acq.Subjects
---
state   : enum("awake", "anesthetized")  # brain state during experiment
%}

classdef Anesthesia < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.Anesthesia');
    end
    
    methods 
        function self = Anesthesia(varargin)
            self.restrict(varargin{:})
        end
    end
end
