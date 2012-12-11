%{
nc.GpfaCovExpl (computed) # Covariance explained by GPFA model

-> nc.GpfaModel
---
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
        popRel = nc.GpfaModel;
    end
    
    methods 
        function self = GpfaCovExpl(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            Y = fetch1(nc.GpfaModelSet(key), 'transformed_data');
            [train, test, model] = fetch1(nc.GpfaModel(key), 'train_set', 'test_set', 'model');
            Qtrain = cov(Ysub(Y, train));
            Qtest = cov(Ysub(Y, test));
            Qpred = model.C * model.C' + model.R;
            tuple = key;
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


function Y = Ysub(Y, index)
    Y = Y(:, :, index);
    Y = reshape(Y, size(Y, 1), size(Y, 2) * size(Y, 3))';
end
