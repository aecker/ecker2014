%{
detect.Params (manual) # Parameters being used for spike detection

-> acq.Ephys
-> detect.Methods
---
ephys_processed_path : varchar(255) # directory containing spike files
use_toolchain = 1    : boolean      # use toolchain or just detect spikes?
%}

classdef Params < dj.Relvar
    properties(Constant)
        table = dj.Table('detect.Params');
    end
    
    methods 
        function self = Params(varargin)
            self.restrict(varargin{:})
        end
    end
end
