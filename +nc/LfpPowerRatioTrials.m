%{
nc.LfpPowerRatioTrials (computed) # LFP power ratio for each trial

-> nc.LfpPowerRatioStim
-> nc.GratingTrials
---
power_ratio_trial   : double    # power ratio for this trial
power_ratio_prctile : double    # percentile of power ratio within session
%}

classdef LfpPowerRatioTrials < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.LfpPowerRatioTrials');
    end
    
    methods 
        function self = LfpPowerRatioTrials(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key, Plow, Phigh)
            ratio = filt(Plow) ./ filt(Phigh);
            prctile = tiedrank(ratio) / numel(ratio);
            for trialNum = 1 : numel(ratio)
                tuple = key;
                tuple.trial_num = trialNum;
                tuple.power_ratio_trial = ratio(trialNum);
                tuple.power_ratio_prctile = prctile(trialNum);
                self.insert(tuple);
            end
        end
    end
end


function y = filt(x)
% Low-pass filter LFP power

n = 50;
win = gausswin(2 * n + 1);
win = win / sum(win);
y = conv(x, win, 'same');
y(1 : n) = y(n);
y(end - n + 1 : end) = y(end - n);
end
