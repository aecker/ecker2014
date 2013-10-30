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
            Cint = zeros(stimTime + 1, nPairs, nCond);
            Cbair  = zeros(stimTime + 1, nPairs, nCond);
            
            fprintf('condition')
            for iCond = 1 : nCond
                fprintf(' %d', iCond)
                
                spikes = fetchn(ae.SpikesByTrial * nc.GratingTrials & key & struct('condition_num', iCond), ...
                    'spikes_by_trial', 'ORDER BY unit_id, trial_num');
                nTrials = numel(spikes) / nUnits;
                spikes = reshape(spikes, nTrials, nUnits);
                spikes = cellfun(@(t) t(t > 0 & t < stimTime), spikes, 'uni', false);
                
                % calculate PSTHs (for shuffle correction) and ACGs
                psth = zeros(stimTime + 1, nUnits);
                A = zeros(2 * stimTime + 1, nUnits);
                for iUnit = 1 : nUnits
                    psth(:, iUnit) = hist(cat(1, spikes{:, iUnit}), 0 : stimTime) / nTrials;
                    Ai = cellfun(@(ti, tj) calcCCG(ti, ti, stimTime), spikes(:, iUnit), spikes(:, iUnit), 'uni', false);
                    Si = conv(psth(:, iUnit), psth(:, iUnit));
                    A(:, iUnit) = mean([Ai{:}], 2) - Si;
                end
                v = sum(A, 1);
                
                % reordering for integration over delta t
                [~, order] = sort(abs(-stimTime : stimTime));
                
                % calculate cross-correlograms & shuffle predictor
                for iPair = 1 : nPairs
                    i = unitIds(1, iPair);
                    j = unitIds(2, iPair);
                    Sij = conv(psth(:, i), psth(:, j));
                    Cij = cellfun(@(ti, tj) calcCCG(ti, tj, stimTime), spikes(:, i), spikes(:, j), 'uni', false);
                    Cij = mean([Cij{:}], 2) - Sij;
                    C(:, iPair, iCond) = Cij;
                    Cintij = cumsum(Cij(order)) / sqrt(v(i) * v(j));
                    Cint(:, iPair, iCond) = Cintij(1 : 2 : end);
                    Cbairij = cumsum(Cij(order)) ./ sqrt(prod(cumsum(A(order, [i j])), 2));
                    Cbair(:, iPair, iCond) = Cbairij(1 : 2 : end);
                end
            end
            fprintf('\n')
            
            % insert into db
            tuple = key;
            tuple.lags = -stimTime : stimTime;
            self.insert(tuple);
            
            C = mean(C, 3);
            Cint = mean(Cint, 3);
            for iPair = 1 : nPairs
                tuple = key;
                tuple.pair_num = pairs(iPair);
                tuple.ccg = C(:, iPair);
                tuple.r_ccg = Cint(:, iPair);
                tuple.r_ccg_bair = Cbair(:, iPair);
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

