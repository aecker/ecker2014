%{
nc.GpfaCovExplPairs (computed) # Covariance explained by GPFA model

-> nc.GpfaCovExpl
unit_i          : tinyint unsigned  # unit i
unit_j          : tinyint unsigned  # unit j
---
train_ij        : double            # covariance matrix of training set
test_ij         : double            # covariance matrix of test set
pred_ij         : double            # predicted covariance matrix
resid_train_ij  : dobule            # residual covariance for training set
resid_test_ij   : dobule            # residual covariance for test set
%}

classdef GpfaCovExplPairs < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.GpfaCovExplPairs');
    end
    
    methods 
        function self = GpfaCovExplPairs(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            [Qtrain, Qtest, Qpred, QresTrain, QresTest, unitIds] = fetch1(nc.GpfaModelSet * nc.GpfaCovExpl & key, ...
                'cov_train', 'cov_test', 'cov_pred', 'cov_resid_train', 'cov_resid_test', 'unit_ids');
            for i = 1 : numel(unitIds)
                for j = i + 1 : numel(unitIds)
                    tuple = key;
                    tuple.unit_i = unitIds(i);
                    tuple.unit_j = unitIds(j);
                    tuple.train_ij = Qtrain(i, j);
                    tuple.test_ij = Qtest(i, j);
                    tuple.pred_ij = Qpred(i, j);
                    tuple.resid_train_ij = QresTrain(i, j);
                    tuple.resid_test_ij = QresTest(i, j);
                    self.insert(tuple);
                end
            end
        end
    end
end
