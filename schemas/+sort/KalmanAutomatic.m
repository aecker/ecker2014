%{
sort.KalmanAutomatic (computed) # my newest table

-> sort.Electrodes
---
model                       : longblob                      # The fitted model
git_hash=""                 : varchar(40)                   # git hash of MoKsm package
kalmanautomatic_ts=CURRENT_TIMESTAMP: timestamp             # automatic timestamp. Do not edit
%}

classdef KalmanAutomatic < dj.Relvar & dj.AutoPopulate

    properties(Constant)
        table = dj.Table('sort.KalmanAutomatic')
        popRel = sort.Electrodes * sort.Methods('sort_method_name = "MoKsm"');
    end

    methods
        function self = KalmanAutomatic(varargin)
            self.restrict(varargin)
        end
    end

    methods (Access=protected)
        function makeTuples( this, key )
            % Cluster spikes
            
            de_key = fetch(detect.Electrodes(key));
            
            m = MoKsmInterface(de_key);

            % treat references differently
            detectMethod = fetch1(detect.Methods & de_key, 'detect_method_name');
            if any(strcmp(detectMethod, {'Tetrodes', 'TetrodesV2'})) && numel(m.tt.w) == 1
                m = getFeatures(m, 'PCA', 4);
                m.params.DriftRate = 100 / 3600 / 1000;
            elseif strcmp(detectMethod, 'SiliconProbes')
                m = getFeatures(m, 'PCA', 8);
                m.params.DriftRate = 300 / 3600 / 1000;
            else
                m = getFeatures(m, 'PCA', 3);
                m.params.DriftRate = 400 / 3600 / 1000;
            end
            
            switch detectMethod
                case {'Tetrodes', 'TetrodesV2'}
                    % Parameters for sorting. Those were tweaked for tetrode
                    % recordings. Other types of data may need substantial
                    % adjustments... [AE]
                    m.params.ClusterCost = 0.002;
                    m.params.Df = 5;
                    m.params.Tolerance = 0.0005;
                case 'SiliconProbes'
                    m.params.ClusterCost = 0.0038;
                    m.params.Df = 8;
                    m.params.Tolerance = 0.00005;
            end
            
            m.params.CovRidge = 1.5;
            m.params.DTmu = 60 * 1000;
            
            fitted = fit(m);
            plot(fitted);
            drawnow
            
            tuple = key;
            tuple.model = saveStructure(compress(fitted));
            tuple.git_hash = gitHash('MoKsm');
            insert(this, tuple);
            
            makeTuples(sort.KalmanTemp, key, fitted);
        end
    end
end
