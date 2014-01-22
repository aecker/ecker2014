%{
sort.KalmanTemp (computed) # temporary model and data for manual step
-> sort.KalmanAutomatic
-----
temp_model: LONGBLOB # The temporary model
kalmantemp_ts=CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef KalmanTemp < dj.Relvar
    
    properties(Constant)
        table = dj.Table('sort.KalmanTemp')
    end
    
    methods
        function self = KalmanTemp(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key, model)
            tuple = key;
            tuple.temp_model = saveStructure(compress(model, model.train));
            insert(self, tuple);
        end
        
        function model = getModel(self)
            assert(count(self) == 1, 'Only for scalar relvars');
            model = fetch1(self, 'temp_model');
            model.Y = model.Features.data';
            model.t = model.SpikeTimes.data';
        end
    end
end
