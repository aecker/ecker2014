%{
sort.KalmanFinalize (computed) # my newest table
-> sort.KalmanManual
-----
final_model: LONGBLOB # The finalized model
kalmanfinalize_ts=CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef KalmanFinalize < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('sort.KalmanFinalize')
		popRel = sort.KalmanManual;
	end

	methods
		function self = KalmanFinalize(varargin)
			self.restrict(varargin)
        end
    end
    
    methods (Access=protected)
        function makeTuples( this, key )
            % Cluster spikes
            %
            % JC 2011-10-21
            close all
            tuple = key;
            
            model = fetch1(sort.KalmanManual & key,'manual_model');
 
            m = MoKsmInterface(model);           
            m = uncompress(m);
            m = updateInformation(m);
            
            tuple.final_model = saveStructure(compress(m));
            insert(this,tuple);
           
            % Insert entries for the single units
            makeTuples(sort.KalmanUnits, key, m);
        end
    end
end
