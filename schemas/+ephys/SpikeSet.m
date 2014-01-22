%{
ephys.SpikeSet (imported) # Import sets of spikes

-> sort.SetsCompleted 
---
spikeset_ts=CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef SpikeSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ephys.SpikeSet');
        popRel = sort.SetsCompleted;
    end
    
    methods 
        function self = SpikeSet(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access=protected)
        function makeTuples( this, key )
            % Import a spike set
            tuple = key;
            
            insert(this,tuple);
	    
    	    makeTuples(ephys.Spikes, key);
        end
    end
end
