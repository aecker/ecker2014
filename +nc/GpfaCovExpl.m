%{
nc.GpfaCovExpl (computed) # Covariance explained by GPFA model

-> nc.GpfaModel
by_trial            : boolean       # use spike counts for entire trial
---
cov_train           : mediumblob    # covariance matrix of training set
cov_test            : mediumblob    # covariance matrix of test set
cov_pred            : mediumblob    # predicted covariance matrix
cov_resid_train     : mediumblob    # residual covariance for training set
cov_resid_test      : mediumblob    # residual covariance for test set
norm_train          : double        # norm for training set
norm_test           : double        # norm for tes set
norm_pred           : double        # norm for prediction
norm_diff_train     : double        # difference in norms for training set
norm_diff_test      : double        # difference in norms for test set
rel_diff_train      : double        # relative difference for training set
rel_diff_test       : double        # relative difference for test set
%}

classdef GpfaCovExpl < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.GpfaCovExpl');
        popRel = nc.GpfaModelSet & 'kfold_cv > 1';
    end
    
    methods 
        function self = GpfaCovExpl(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            Yt = fetch1(nc.GpfaModelSet & key, 'transformed_data');
            for key = fetch(nc.GpfaModel & key)'
                [train, test, model] = fetch1(nc.GpfaModel & key, 'train_set', 'test_set', 'model');
                model = GPFA(model);
                for byTrial = [false true]
                    Qtrain = cov(Ysub(Yt, train, byTrial));
                    Qtest = cov(Ysub(Yt, test, byTrial));
                    if byTrial
                        Qpred = model.T * model.R;
                        for i = 1 : model.p
                            K = toeplitz(model.covFun(0 : model.T - 1, model.gamma(i)));
                            Qpred = Qpred + (model.C(:, i) * model.C(:, i)') * sum(K(:));
                        end
                    else
                        Qpred = model.C * model.C' + model.R;
                    end
                    tuple = key;
                    tuple.by_trial = byTrial;
                    tuple.cov_train = Qtrain;
                    tuple.cov_test = Qtest;
                    tuple.cov_pred = Qpred;
                    if byTrial
                        tuple.cov_resid_train = model.residCovByTrial(Yt(:, :, train));
                        tuple.cov_resid_test = model.residCovByTrial(Yt(:, :, test));
                    else
                        tuple.cov_resid_train = model.residCov(Yt(:, :, train));
                        tuple.cov_resid_test = model.residCov(Yt(:, :, test));
                    end
                    tuple.norm_diff_train = norm(Qtrain - Qpred, 'fro');
                    tuple.norm_diff_test = norm(Qtest - Qpred, 'fro');
                    tuple.norm_train = norm(Qtrain, 'fro');
                    tuple.norm_test = norm(Qtest, 'fro');
                    tuple.norm_pred = norm(Qpred, 'fro');
                    tuple.rel_diff_train = tuple.norm_diff_train / tuple.norm_train;
                    tuple.rel_diff_test = tuple.norm_diff_test / tuple.norm_test;
                    self.insert(tuple);
                end
            end
        end
    end
    
end


function Y = Ysub(Y, index, byTrial)
    Y = Y(:, :, index);
    if byTrial
        Y = permute(sum(Y, 2), [3 1 2]);
    else
        Y = Y(1 : end, :)';
    end
end
