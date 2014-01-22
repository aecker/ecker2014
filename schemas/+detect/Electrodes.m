%{
detect.Electrodes (imported) # spike detection for one electrode
      
-> detect.Sets
electrode_num         : tinyint unsigned # electrode number in array
---
detect_electrode_file : varchar(255)     # name of file containing spikes
%}

classdef Electrodes < dj.Relvar
    properties(Constant)
        table = dj.Table('detect.Electrodes');
    end
    
    methods 
        function self = Electrodes(varargin)
            self.restrict(varargin{:})
        end
    end
end
