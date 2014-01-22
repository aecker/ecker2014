%{
nc.LfpGlmSet (computed) # GLM with LFP as input

-> ae.LfpSet
-> nc.Gratings
-> ae.SpikesByTrialSet
-> nc.UnitStatsSet
-> nc.LfpGlmParams
---
control     : boolean       # control with shorter stim time?
%}

classdef LfpGlmSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.LfpGlmSet');
        popRel = nc.Anesthesia * ae.LfpSet * nc.Gratings * ae.SpikesByTrialSet * nc.UnitStatsSet * nc.LfpGlmParams;
    end

    methods(Access = protected)
        function makeTuples(self, key)
            
            offset = 30;    % offset from stimulus onset to account for latencies
            eps = 0.01 / 1000 * key.bin_size;
            kfold = key.kfold_cv;
            Fs = 1000 / key.bin_size;
            
            stimTime = fetch1(nc.Gratings & key, 'stimulus_time');
            stimTimeLimit = key.spike_count_end - key.spike_count_start;
            
            assert(any(stimTime == [500 2000]), 'Stimulus time must be 500 or 2000 ms!')

            % extract LFP
            rel = ae.Lfp * acq.EphysStimulationLink & ephys.Spikes & key;
            lfp = fetchn(rel, 'lfp');
            [Flfp, t0] = fetch1(rel, 'lfp_sampling_rate', 'lfp_t0', 'LIMIT 1');
            [p, q] = rat(Fs / Flfp, 1e-3);
            assert(p < 100 && q < 100, 'Problem with resampling LFP!')
            lfp = cellfun(@(x) resample(x, p, q), lfp, 'uni', false);
            lfp = mean(cat(3, lfp{:}), 3);
            
            tuple = key;
            tuple.control = stimTimeLimit < stimTime;
            self.insert(tuple);
            
            for key = fetch(self.popRel * nc.GratingConditions & key)'
                nBins = round(stimTimeLimit / key.bin_size);
                
                % remove stimulus-evoked component from LFP
                showStims = sort(double(fetchn(stimulation.StimTrialEvents * nc.GratingTrials...
                    & key & 'event_type = "showStimulus"', 'event_time')));
                nTrials = numel(showStims);
                ndx = bsxfun(@plus, round((showStims + 30 + key.bin_size / 2 - t0) * Fs / 1000), 1 : nBins)';
                Z = lfp(ndx);
                Z = bsxfun(@minus, Z, mean(Z, 2));
                
                % constraints to enforce mean firing rate and stability for all cells
                unitConstraints = 'mean_rate_cond > 0.5 AND tac_instability < 0.1';
                unitStats = nc.UnitStats * nc.UnitStatsConditions;
                nUnits = count(unitStats & key & unitConstraints);
                
                % get spikes
                rel = ae.SpikesByTrial * nc.GratingTrials * unitStats;
                data = fetch(rel & key & unitConstraints, 'spikes_by_trial', 'ORDER BY trial_num, unit_id');
                data = reshape(data, nUnits, nTrials);
                bins = offset + (0 : nBins) * key.bin_size;
                Y = zeros(nUnits, nBins, nTrials);
                for iTrial = 1 : nTrials
                    for iUnit = 1 : nUnits
                        xi = histc(data(iUnit, iTrial).spikes_by_trial, bins);
                        Y(iUnit, :, iTrial) = xi(1 : nBins);
                    end
                end
                Y = Y + eps;
                unitIds = fetchn(unitStats & key & unitConstraints, 'unit_id');
                
                % partition data for cross-validation
                part = round(linspace(0, nTrials, kfold + 1));
                
                for k = 1 : kfold
                    
                    if kfold > 1
                        test = part(k) + 1 : part(k + 1);
                        train = setdiff(1 : nTrials, test);
                    else
                        test = 1 : nTrials;
                        train = 1 : nTrials;
                    end
                    
                    % create design matrix
                    Xtrain = [reshape(Z(:, train), [], 1), repmat(eye(nBins), numel(train), 1)];
                    Xtest = [reshape(Z(:, test), [], 1), repmat(eye(nBins), numel(test), 1)];
                    Ytrain = reshape(Y(:, :, train), nUnits, [])';
                    Ytest = reshape(Y(:, :, test), nUnits, [])';
                    
                    % fit GLMs
                    for i = 1 : nUnits
                        
                        % with LFP
                        b = glmfit(Xtrain, Ytrain(:, i), 'poisson', 'constant', 'off');
                        Yh_train = glmval(b, Xtrain, 'log', 'constant', 'off');
                        Yh_test = glmval(b, Xtest, 'log', 'constant', 'off');
                        
                        % without LFP
                        b0 = glmfit(Xtrain(:, 2 : end), Ytrain(:, i), 'poisson', 'constant', 'off');
                        Yh0_train = glmval(b0, Xtrain(:, 2 : end), 'log', 'constant', 'off');
                        Yh0_test = glmval(b0, Xtest(:, 2 : end), 'log', 'constant', 'off');
                        
                        % variance explained
                        ve = @(y, yh, yh0) (var(y - yh0) - var(y - yh)) / var(y - yh0);
                        
                        tuple = key;
                        tuple.unit_id = unitIds(i);
                        tuple.cv_run = k;
                        tuple.lfp_weight = b(1);
                        tuple.psth_weights = b(2 : end);
                        tuple.all_weights = b;
                        tuple.ve_train = ve(Ytrain(:, i), Yh_train, Yh0_train);
                        tuple.ve_test = ve(Ytest(:, i), Yh_test, Yh0_test);
                        tuple.ve_train_log = ve(log(Ytrain(:, i)), log(Yh_train), log(Yh0_train));
                        tuple.ve_test_log = ve(log(Ytest(:, i)), log(Yh_test), log(Yh0_test));
                        insert(nc.LfpGlm, tuple);
                    end
                end
            end
        end
    end
end
