%{
nc.GpfaResidCorrSet (computed) # Residual correlations for GPFA model

-> nc.GpfaModelSet
---
%}

classdef GpfaResidCorrSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.GpfaResidCorrSet');
        popRel = nc.GpfaParams * nc.GpfaModelSet & 'kfold_cv > 1';
    end

    methods (Access = protected)
        function makeTuples(self, key)
            self.insert(key);
            Yt = fetch1(nc.GpfaModelSet & key, 'transformed_data');
            T = size(Yt, 2);
            par = fetch(nc.GpfaParams & key, '*');
            coeff = @(C) C ./ sqrt(diag(C) * diag(C)');
            for p = 0 : par.max_latent_dim
                for int = 1 : T
                    VEtrain = 0;
                    VEtest = 0;
                    Qtrain = 0;
                    Qtest = 0;
                    for k = 1 : par.kfold_cv
                        modelKey = key;
                        modelKey.latent_dim = p;
                        modelKey.cv_run = k;
                        [train, test, model] = fetch1(nc.GpfaModel & modelKey, 'train_set', 'test_set', 'model');
                        model = GPFA(model);
                        
                        % training set
                        Ytrain = Yt(:, :, train);
                        [Q, VE] = residCovVarExplInt(model, Ytrain, int);
                        Qtrain = Qtrain + Q;
                        VEtrain = VEtrain + VE / par.kfold_cv;
                        
                        % test set
                        Ytest = Yt(:, :, test);
                        [Q, VE] = residCovVarExplInt(model, Ytest, int);
                        Qtest = Qtest + Q;
                        VEtest = VEtest + VE / par.kfold_cv;
                    end
                    Rtrain = coeff(Qtrain);
                    Rtest = coeff(Qtest);

                    % insert residual correlations
                    [ii, jj, pairs] = fetchn(nc.GpfaPairs & key, 'index_i', 'index_j');
                    tuple = key;
                    tuple.latent_dim = p;
                    tuple.int_bins = int;
                    for iPair = 1 : numel(pairs)
                        tuple.pair_num = pairs(iPair).pair_num;
                        tuple.resid_corr_train = Rtrain(ii(iPair), jj(iPair));
                        tuple.resid_corr_test = Rtest(ii(iPair), jj(iPair));
                        insert(nc.GpfaResidCorr, tuple);
                    end

                    % insert variance explained per cell
                    unitIds = fetchn(nc.GpfaUnits & key, 'unit_id', 'ORDER BY unit_id');
                    for iUnit = 1 : numel(unitIds)
                        tuple = key;
                        tuple.latent_dim = p;
                        tuple.int_bins = int;
                        tuple.unit_id = unitIds(iUnit);
                        tuple.ve_train = VEtrain(iUnit);
                        tuple.ve_test = VEtest(iUnit);
                        insert(nc.GpfaVE, tuple);
                    end
                end
            end
        end
    end
end


function Q = residCovInt(model, Y, k)
% Residual covariance for spike counts integrated over k bins.

T = model.T; N = size(Y, 3); p = model.p; C = model.C;
[X, VarX] = model.estX(Y);
Ct = repmat(C, 1, k);
Q = 0;
for i = 0 : T - k
    ndx = (1 : k) + i;
    Xi = reshape(X(:, ndx, :), [p * k, N]);
    Yi = model.subtractMean(Y);
    Yi = permute(sum(Yi(:, ndx, :), 2), [1 3 2]);
    CXYi = Ct * Xi * Yi';
    ndx = (1 : k * p) + i * p;
    EXX = N * VarX(ndx, ndx) + Xi * Xi';
    Q = Q + Yi * Yi' - CXYi - CXYi' + Ct * EXX * Ct';
end
Q = Q / N / (T - k + 1);

end


function [Q, VE] = residCovVarExplInt(model, Y, k)
% Compute variance explained for spike counts integrated over k bins

Q = residCovInt(model, Y, k);
Y = model.subtractMean(Y);
Y = convn(Y, ones(1, k), 'valid');
V = mean(Y(:, :) .^ 2, 2);
VE = 1 - diag(Q) ./ V;

end


function ve = varExplByBin(self, Y)
% Compute variance explained for spike counts per bin..

Y0 = self.subtractMean(Y);
V = mean(Y0(:, :) .^ 2, 2);
R = self.residCovByBin(Y);
ve = 1 - diag(R) ./ V;
end


function ve = varExplByTrial(self, Y)
% Compute variance explained for spike counts of entire trial.

Y0 = self.subtractMean(Y);
V = mean(sum(Y0, 2) .^ 2, 3);
R = self.residCovByTrial(Y);
ve = 1 - diag(R) ./ V;
end
