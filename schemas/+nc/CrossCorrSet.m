%{
nc.CrossCorrSet (computed) # Cross-correlograms

-> nc.Gratings
-> ae.SpikesByTrialSet
-> nc.UnitPairSet
---
lags    : mediumblob        # time lags used for CCG
%}

classdef CrossCorrSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.CrossCorrSet');
        popRel = nc.Gratings * ae.SpikesByTrialSet * nc.UnitPairSet & nc.AnalysisStims;
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            nCond = count(nc.GratingConditions & key);
            nUnits = count(ephys.Spikes & key);
            stimTime = fetch1(nc.Gratings & key, 'stimulus_time');
            
            [unitIds, pairs] = fetchn(nc.UnitPairs * nc.UnitPairMembership & key, 'unit_id', 'pair_num', 'ORDER BY pair_num');
            pairs = pairs(1 : 2 : end);
            unitIds = reshape(unitIds, 2, []);
            nPairs = numel(pairs);

            C = zeros(2 * stimTime + 1, nPairs, nCond);
            CS = C;
            Cint = zeros(stimTime + 1, nPairs, nCond);
            Cbair  = Cint;
            CSint = Cint;
            CSbair = Cint;
            
            fprintf('condition')
            for iCond = 1 : nCond
                fprintf(' %d', iCond)
                
                spikes = fetchn(ae.SpikesByTrial * nc.GratingTrials & key & struct('condition_num', iCond), ...
                    'spikes_by_trial', 'ORDER BY unit_id, trial_num');
                nTrials = numel(spikes) / nUnits;
                spikes = reshape(spikes, nTrials, nUnits);
                spikes = cellfun(@(t) t(:), spikes, 'uni', false);
                spikes = cellfun(@(t) t(t > 0 & t < stimTime), spikes, 'uni', false);
                
                % calculate PSTHs (for shuffle correction) and ACGs
                psth = zeros(stimTime + 1, nUnits);
                A = zeros(2 * stimTime + 1, nUnits);
                AS = A;
                for iUnit = 1 : nUnits
                    psth(:, iUnit) = hist(cat(1, spikes{:, iUnit}), 0 : stimTime) / nTrials;
                    Ai = cellfun(@(ti) calcCCG(ti, ti, stimTime), spikes(:, iUnit), 'uni', false);
                    ASi = cellfun(@(ti, tj) calcCCG(ti, tj, stimTime), spikes(1 : end - 1, iUnit), spikes(2 : end, iUnit), 'uni', false);
                    Si = xcorr(psth(:, iUnit), psth(:, iUnit));
                    A(:, iUnit) = mean([Ai{:}], 2) - Si;
                    AS(:, iUnit) = mean([Ai{:}], 2) - mean([ASi{:}], 2);
                end
                fr = sum(psth, 1);
                A = bsxfun(@rdivide, A, fr);
                AS = bsxfun(@rdivide, AS, fr);
                v = sum(A, 1);
                vs = sum(AS, 1);
                
                % reordering for integration over delta t
                [~, order] = sort(abs(-stimTime : stimTime));
                
                % calculate cross-correlograms & shuffle predictor
                for iPair = 1 : nPairs
                    i = unitIds(1, iPair);
                    j = unitIds(2, iPair);
                    
                    % using all-way shuffle predictor
                    Sij = xcorr(psth(:, i), psth(:, j));
                    CC = cellfun(@(ti, tj) calcCCG(ti, tj, stimTime), spikes(:, i), spikes(:, j), 'uni', false);
                    Cij = (mean([CC{:}], 2) - Sij) / sqrt(fr(i) * fr(j));
                    C(:, iPair, iCond) = Cij;
                    Cintij = cumsum(Cij(order)) / sqrt(v(i) * v(j));
                    Cint(:, iPair, iCond) = Cintij(1 : 2 : end);
                    Cbairij = cumsum(Cij(order)) ./ sqrt(prod(cumsum(A(order, [i j])), 2));
                    Cbair(:, iPair, iCond) = Cbairij(1 : 2 : end);
                    
                    % using one-trial shift predictor
                    CCS = cellfun(@(ti, tj) calcCCG(ti, tj, stimTime), spikes(1 : end - 1, i), spikes(2 : end, j), 'uni', false);
                    CSij = (mean([CC{:}], 2) - mean([CCS{:}], 2)) / sqrt(fr(i) * fr(j));
                    CS(:, iPair, iCond) = CSij;
                    CSintij = cumsum(CSij(order)) / sqrt(vs(i) * vs(j));
                    CSint(:, iPair, iCond) = CSintij(1 : 2 : end);
                    CSbairij = cumsum(CSij(order)) ./ sqrt(prod(cumsum(AS(order, [i j])), 2));
                    CSbair(:, iPair, iCond) = CSbairij(1 : 2 : end);
                end
            end
            fprintf('\n')
            
            % insert into db
            tuple = key;
            tuple.lags = -stimTime : stimTime;
            self.insert(tuple);
            
            win = triang(size(C, 1));
            C = bsxfun(@rdivide, nanmean(C, 3), win);
            CS = bsxfun(@rdivide, nanmean(CS, 3), win);
            Cint = nanmean(Cint, 3);
            Cbair = nanmean(Cbair, 3);
            CSint = nanmean(CSint, 3);
            CSbair = nanmean(CSbair, 3);
            for iPair = 1 : nPairs
                tuple = key;
                tuple.pair_num = pairs(iPair);
                tuple.ccg = C(:, iPair);
                tuple.ccg_shift = CS(:, iPair);
                tuple.r_ccg = Cint(:, iPair);
                tuple.r_ccg_bair = Cbair(:, iPair);
                tuple.r_ccg_shift = CSint(:, iPair);
                tuple.r_ccg_shift_bair = CSbair(:, iPair);
                insert(nc.CrossCorr, tuple);
            end
        end
    end
end



function ccg = calcCCG(ti, tj, stimTime)
    ti = ti(ti > 0 & ti < stimTime);
    tj = tj(tj > 0 & tj < stimTime);
    if isempty(ti) || isempty(tj)
        ccg = zeros(2 * stimTime + 1, 1);
    else
        dt = bsxfun(@minus, ti, tj');
        ccg = hist(dt(:), -stimTime : stimTime);
        ccg = ccg(:);
    end
end

