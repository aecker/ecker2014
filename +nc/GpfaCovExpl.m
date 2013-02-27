%{
nc.GpfaCovExpl (computed) # Covariance explained by GPFA model

-> nc.GpfaModelSet
latent_dim           : tinyint unsigned  # number of latent dimensions
by_trial             : boolean       # use spike counts for entire trial
---
avg_var_expl_train   : double        # average variance explained on train set
avg_var_expl_test    : double        # average variance explained on test set
corr_resid_train     : mediumblob    # residual cov for train set (avg over CV runs)
corr_resid_test      : mediumblob    # residual cov for test set (avg over CV runs)
rmsd_corr_pred_train : double        # RMS diff of offdiags for prediction and train set
rmsd_corr_pred_test  : double        # RMS diff of offdiags for prediction and train set
rmsd_corr_train_test : double        # RMS diff of offdiags for prediction and train set
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
                        Qrtrain = Qrtrain + model.residCov(Ytrain, byTrial);
                        Qrtest = Qrtest + model.residCov(Ytest, byTrial);
                        Qpred = model.C * model.C' + model.R;

                        % RMS difference of predicted and observed correlations
                        Y0train = model.subtractMean(Ytrain);
                        Y0test = model.subtractMean(Ytest);
                        if byTrial
                            Qtrain = corrcoef(permute(sum(Y0train, 2), [3 1 2]));
                            Qtest = corrcoef(permute(sum(Y0test, 2), [3 1 2]));
                        else
                            Qtrain = corrcoef(Y0train(1 : end, :)');
                            Qtest = corrcoef(Y0test(1 : end, :)');
                        end
                        rmsPredTrain = rmsPredTrain + sqrt(mean(offdiag(Qpred - Qtrain) .^ 2)) / par.kfold_cv;
                        rmsPredTest = rmsPredTest + sqrt(mean(offdiag(Qpred - Qtest) .^ 2)) / par.kfold_cv;
                        rmsTrainTest = rmsTrainTest + sqrt(mean(offdiag(Qtrain - Qtest) .^ 2)) / par.kfold_cv;
                    end

                    % insert into database
                    tuple = key;
                    tuple.latent_dim = p;
                    tuple.by_trial = byTrial;
                    tuple.avg_var_expl_train = mean(vetrain);
                    tuple.avg_var_expl_test = mean(vetest);
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
                        insert(nc.GpfaVarExpl, tuple);
                    end
                end
            end
        end
    end
end
