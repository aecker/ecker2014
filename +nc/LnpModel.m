%{
nc.LnpModel (computed) # Firing rate prediction from LFP

-> nc.LnpModelSet
-> ae.SpikesByTrial
---
ori_phase       : double            # phase of orientation parameter
ori_mag         : double            # magnitude orientation parameter
lfp_param       : double            # parameter for lfp dependence
const_param     : double            # constant parameter
perc_var        : float             # percent variance explained
%}

% NOTE: LFP from tetrode that recorded the neuron is used. I may extend
%       this to try all LFPs. In this case augment the PK by:
% electrode_num   : tinyint unsigned  # electrode number

% The model we fit is:
%   r = exp(a*s + b*x + c)
%
% where
%   stimlus:    s = [cos(theta), sin(theta)]
%   LFP:        x
%
%   ori_phase = atan2(a)
%   ori_mag = norm(a)
%   lfp_param = b
%   const_param = c
%
% If use_lfp = false the LFP term is ignored.

classdef LnpModel < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.LnpModel');
    end
    
    methods 
        function self = LnpModel(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(this, key)
            assert(key.use_lfp == 1, 'Model without LFP not implemented yet!')
            
            [lfpPre, lfpFs] = fetch1(ae.LfpByTrialSet(key), 'pre_stim_time', 'lfp_sampling_rate');
            [winStart, winEnd] = fetch1(nc.LnpModelSet(key), 'win_start', 'win_end');
            t = (winStart:winEnd)';
            nBins = numel(t);
            
            rel = (stimulation.StimTrials * nc.GratingTrials * ae.SpikesByTrial * ae.LfpByTrial * ephys.Spikes) & key & 'valid_trial = true';
            [spikes, condition, lfp] = fetchn(rel, 'spikes_by_trial', 'condition_num', 'lfp_by_trial');
            
            % extract LFP in window of interest
            minSamples = min(cellfun(@numel, lfp));
            tlfp = (0:minSamples-1)' * 1000 / lfpFs - lfpPre;
            lfp = cellfun(@(x) interp1q(tlfp, x, t), lfp, 'UniformOutput', false);
            lfp = [lfp{:}];

            % compute mean lfp for each stimulus
            uCond = unique(condition);
            nCond = numel(uCond);
            meanLfp = zeros(nBins, nCond);
            for i = 1:nCond
                meanLfp(:, i) = mean(lfp(:, condition == uCond(i)), 2);
            end
            
            nTrials = numel(spikes);
            X = zeros(nBins * nTrials, nCond + 1);
            S = zeros(nBins * nTrials, 1);
            for i = 1:nTrials
                % compute input vector
                stimulus = zeros(nBins, nCond);
                stimulus(:, condition(i)) = 1;
                trialLfp = lfp(:, i) - meanLfp(:, condition(i));
                bins = nBins * (i - 1) + (1:nBins);
                X(bins, :) = [stimulus, trialLfp];
                
                % spikes
                s = spikes{i};
                S(bins(1) + fix(s(s > winStart & s < winEnd) - winStart)) = 1;
            end
            
            % CHECKME
            b = glmfit(X, S, 'binomial', 'link', 'log', 'constant', 'off');
           
            
            % TODO: insert into db
            
            % TODO: think about how to evaluate variance explained
            
        end
    end
end
