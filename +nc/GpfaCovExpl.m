%{
nc.GpfaCovExpl (computed) # Covariance explained by GPFA model

-> nc.GpfaModelSet
latent_dim           : tinyint unsigned  # number of latent dimensions
by_trial             : boolean           # use spike counts for entire trial
---
avg_var_expl_train          : double     # avg var expl on train set model based
avg_var_expl_test           : double     # avg var expl on test set model based
avg_var_unexpl_train        : double     # avg var unexpl on train set model based
avg_var_unexpl_test         : double     # avg var unexpl on test set model based
avg_var_expl_corr_train = 0 : double     # avg corr between predicted and observed on train set
avg_var_expl_corr_test = 0  : double     # avg corr between predicted and observed on test set
corr_resid_train            : mediumblob # residual cov for train set (avg over CV runs)
corr_resid_test             : mediumblob # residual cov for test set (avg over CV runs)
rmsd_corr_pred_train        : double     # RMS diff of offdiags for prediction and train set
rmsd_corr_pred_test         : double     # RMS diff of offdiags for prediction and train set
rmsd_corr_train_test        : double     # RMS diff of offdiags for prediction and train set
%}

classdef GpfaCovExpl < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.GpfaCovExpl');
        popRel = nc.GpfaParams * nc.GpfaModelSet & 'kfold_cv > 1';
    end

    methods 
        function self = GpfaCovExpl(varargin)
            self.restrict(varargin{:})
        end
    end

    methods (Access = protected)
        function makeTuples(self, key)
            Yt = fetch1(nc.GpfaModelSet & key, 'transformed_data');
            par = fetch(nc.GpfaParams & key, '*');
            coeff = @(C) C ./ sqrt(diag(C) * diag(C)');
            for p = 0 : par.max_latent_dim
                for byTrial = [false, true]
                    vetrain = 0;
                    vetest = 0;
                    vutrain = 0;
                    vutest = 0;
                    vectrain = 0;
                    vectest = 0;
                    Qrtrain = 0;
                    Qrtest = 0;
                    rmsPredTrain = 0;
                    rmsPredTest = 0;
                    rmsTrainTest = 0;
                    for k = 1 : par.kfold_cv
                        modelKey = key;
                        modelKey.latent_dim = p;
                        modelKey.cv_run = k;
                        [train, test, model] = fetch1(nc.GpfaModel & modelKey, 'train_set', 'test_set', 'model');
                        model = GPFA(model);
                        Ytrain = Yt(:, :, train);
                        Ytest = Yt(:, :, test);

                        % variance explained
                        vetrain = vetrain + model.varExpl(Ytrain, byTrial) / par.kfold_cv;
                        vetest = vetest + model.varExpl(Ytest, byTrial) / par.kfold_cv;

                        % residual correlations
                        Rtrain = model.residCov(Ytrain, byTrial);
                        Qrtrain = Qrtrain + Rtrain;
                        Rtest = model.residCov(Ytest, byTrial);
                        Qrtest = Qrtest + Rtest;
                        Qpred = coeff(model.C * model.C' + model.R);

                        % RMS difference of predicted and observed correlations
                        [Qtrain, Y0train, Y0ptrain] = process(model, Ytrain, byTrial);
                        [Qtest, Y0test, Y0ptest] = process(model, Ytest, byTrial);
                        rmsPredTrain = rmsPredTrain + sqrt(mean(offdiag(Qpred - coeff(Qtrain)) .^ 2)) / par.kfold_cv;
                        rmsPredTest = rmsPredTest + sqrt(mean(offdiag(Qpred - coeff(Qtest)) .^ 2)) / par.kfold_cv;
                        rmsTrainTest = rmsTrainTest + sqrt(mean(offdiag(coeff(Qtrain) - coeff(Qtest)) .^ 2)) / par.kfold_cv;

                        % variance unexplained
                        vutrain = vutrain + diag(Rtrain ./ Qtrain) / par.kfold_cv;
                        vutest = vutest + diag(Rtest ./ Qtest) / par.kfold_cv;

                        % variance explained via correlation of observed
                        % and predictes spike counts
                        vectrain = vectrain + corr(Y0train, Y0ptrain) / par.kfold_cv;
                        vectest = vectest + corr(Y0test, Y0ptest) / par.kfold_cv;
                    end

                    % insert into database
                    tuple = key;
                    tuple.latent_dim = p;
                    tuple.by_trial = byTrial;
                    tuple.avg_var_expl_train = mean(vetrain);
                    tuple.avg_var_expl_test = mean(vetest);
                    tuple.avg_var_unexpl_train = mean(vutrain);
                    tuple.avg_var_unexpl_test = mean(vutest);
                    tuple.avg_var_expl_corr_train = mean(vectrain);
                    tuple.avg_var_expl_corr_test = mean(vectest);
                    tuple.corr_resid_train = coeff(Qrtrain);
                    tuple.corr_resid_test = coeff(Qrtest);
                    tuple.rmsd_corr_pred_train = rmsPredTrain;
                    tuple.rmsd_corr_pred_test = rmsPredTest;
                    tuple.rmsd_corr_train_test = rmsTrainTest;
                    self.insert(tuple);

                    % insert variance explained per cell
                    unitIds = fetchn(nc.GpfaUnits & key, 'unit_id', 'ORDER BY unit_id');
                    nUnits = numel(unitIds);
                    for i = 1 : nUnits
                        tuple = key;
                        tuple.latent_dim = p;
                        tuple.by_trial = byTrial;
                        tuple.unit_id = unitIds(i);
                        tuple.var_expl_train = vetrain(i);
                        tuple.var_expl_test = vetest(i);
                        tuple.var_unexpl_train = vutrain(i);
                        tuple.var_unexpl_test = vutest(i);
                        tuple.var_expl_corr_train = vectrain(i);
                        tuple.var_expl_corr_test = vectest(i);
                        insert(nc.GpfaVarExpl, tuple);
                    end
                end
            end
        end
    end
end


function [Q, Y0, Y0p] = process(model, Y, byTrial)

Y0 = model.subtractMean(Y);
Yp = model.predict(Y);
Y0p = model.subtractMean(Yp);
if byTrial
    Y0 = permute(sum(Y0, 2), [3 1 2]);
    Y0p = permute(sum(Y0p, 2), [3 1 2]);
else
    Y0 = Y0(1 : end, :)';
    Y0p = Y0p(1 : end, :)';
end
Q = cov(Y0, 1);
end


function c = corr(x, y)
% Pairwise correlation coefficient (to avoid use of stats toolbox)

n = size(x, 2);
c = zeros(1, n);
for i = 1 : n
    tmp = corrcoef([x(:, i) y(:, i)]);
    c(i) = tmp(1, 2);
end
end
