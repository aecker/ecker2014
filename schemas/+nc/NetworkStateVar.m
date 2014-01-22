%{
nc.NetworkStateVar (computed) # Variance of network state inferred by GPFA

-> ae.SpikesByTrialSet
-> nc.UnitPairSet
-> nc.GpfaParams
-> nc.DataTransforms
-> nc.NetworkStateVarParams
---
var_x   : longblob          # variance of network state in sliding window
%}

classdef NetworkStateVar < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.NetworkStateVar');
        popRel = ae.SpikesByTrialSet * nc.UnitPairSet * nc.GpfaParams ...
            * nc.DataTransforms * nc.NetworkStateVarParams ...
            & 'transform_num = 5 AND bin_size = 100' ...
            & 'max_latent_dim = 1 AND kfold_cv = 1 AND zscore = 0' ...
            & 'max_instability = 0.1 AND min_rate = 0.5 AND sort_method_num = 5' ...
            & (nc.AnalysisStims & 'state = "anesthetized"');
    end
    
    methods (Access = protected)
        function makeTuples(self, key)

            key.control = 0;
            data = fetch(stimulation.StimTrials * nc.GratingTrials ...
                & nc.GpfaModel & key, 'trial_num', 'condition_num');
            data = dj.struct.sort(data, 'trial_num');
            trials = [data.trial_num];
            conditions = [data.condition_num];
            X = zeros(1, numel(trials));
            for modelKey = fetch(nc.GpfaModel & key & 'cv_run = 1 AND latent_dim = 1 AND control = false')'
                [Y, model] = fetch1(nc.GpfaModelSet * nc.GpfaModel & key & modelKey, 'transformed_data', 'model');
                model = GPFA(model);
                Xi = model.estX(Y);
                X(1 : size(Xi, 2), conditions == modelKey.condition_num) = Xi;
            end
            X = reshape(X, [], 2 * key.num_blocks);
            VarX = sum(X .^ 2, 1);
            VarX = VarX(1 : end - 1) + VarX(2 : end);
            VarX = VarX / numel(X) * key.num_blocks;
            
            tuple = rmfield(key, 'control');
            tuple.var_x = VarX;
            self.insert(tuple);
        end
    end
end
