%{
ephys.SingleUnit (computed) # A spike train from a single or multi unit

-> ephys.Spikes
---
cluster_number              : int unsigned                  # The cluster number
snr                         : double                        # The SNR of this unit
fp                          : double                        # The FP of this unit
fn                          : double                        # The FN of this unit
singleunit_ts=CURRENT_TIMESTAMP : timestamp                     # automatic timestamp. Do not edit
%}

classdef SingleUnit < dj.Relvar
    properties(Constant)
        table = dj.Table('ephys.SingleUnit');
    end
    
    methods 
        function self = SingleUnit(varargin)
            self.restrict(varargin{:})
        end
        
        % Note: not implementing makeTuples - get information when
        % inserting spikes
        
    end
end
