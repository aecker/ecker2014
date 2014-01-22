%{
sort.KalmanManual (computed) # manual processing step

-> sort.KalmanAutomatic
---
manual_model                : longblob                      # The manually processed model
kalmanmanual_ts=CURRENT_TIMESTAMP: timestamp                # automatic timestamp. Do not edit
comment=""                  : varchar(255)                  # comment on manual step
%}

classdef KalmanManual < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('sort.KalmanManual')
        popRel = sort.KalmanAutomatic & sort.KalmanTemp;
    end
    
    methods
        function self = KalmanManual(varargin)
            self.restrict(varargin)
        end
        
        function review(self)
            % Review manual clustering model
            
            assert(count(self) == 1, 'relvar must be scalar!')
            disp 'Review only. No changes will take effect!'
            disp 'If you need to change something, delete the tuple and redo it.'
            title = fetch1(self * detect.Electrodes, 'detect_electrode_file');
            title = ['|| READ ONLY || ' title ' || READ ONLY ||'];
            model = uncompress(MoKsmInterface(fetch1(self, 'manual_model')));
            ManualClustering(model, title)
        end
    end

    methods (Access=protected)
        function makeTuples( this, key )

            model = getModel(sort.KalmanTemp & key);
            model.params.Verbose = false;
 
            model = MoKsmInterface(model);
            [model, comment] = ManualClustering(model, fetch1(detect.Electrodes & key, 'detect_electrode_file'));
            
            if ~isempty(model)
                tuple = key;
                tuple.manual_model = saveStructure(compress(model));
                tuple.comment = comment(1 : min(end, 255));
                insert(this, tuple);
            else
                warning('KalmanAutomatic:canceled', 'Manual processing canceled. Not inserting anything!')
            end
        end
    end
end
