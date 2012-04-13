%{
nc.LnpModelParams (manual)  # Parameters for LNP model

use_lfp     : boolean       # include LFP term in rate prediction
win_start   : smallint      # start of time window (relative to stim onset)
win_end     : smallint      # end of window
---
%}

classdef LnpModelParams < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.LnpModelParams');
    end
    
    methods 
        function self = LnpModelParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
