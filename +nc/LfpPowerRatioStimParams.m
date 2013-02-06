%{
nc.LfpPowerRatioStimParams (manual) # LFP power ratio parameters

low_min     : double    # low frequency min
low_max     : double    # low frequency max
high_min    : double    # high frequency min
high_max    : double    # high frequency max
win_start   : int       # start of window relative to stim onset
win_end     : int       # end of window relative to stim onset
---
%}

classdef LfpPowerRatioStimParams < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.LfpPowerRatioStimParams');
    end
    
    methods
        function self = LfpPowerRatioStimParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
