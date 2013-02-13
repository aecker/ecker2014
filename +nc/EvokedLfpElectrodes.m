%{
nc.EvokedLfpElectrodes (computed) # electrodes used for eevoked LFP profile

-> nc.EvokedLfpProfile
electrode_num       : tinyint unsigned  # electode number
---
%}

classdef EvokedLfpElectrodes < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.EvokedLfpElectrodes');
    end
    
    methods 
        function self = EvokedLfpElectrodes(varargin)
            self.restrict(varargin{:})
        end
    end
end
