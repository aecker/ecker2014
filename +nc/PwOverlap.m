%{
nc.PwOverlap (computed) # Pairwise cluster overlap

-> nc.PwOverlapSet
-> nc.UnitPairs
---
min_contam  : double    # minimum contam (cluster with lower % fp)
max_contam  : double    # max contam
avg_contam  : double    # average contam (total % fp of both clusters)
%}

classdef PwOverlap < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.PwOverlap');
    end
    
    methods 
        function self = PwOverlap(varargin)
            self.restrict(varargin{:})
        end
    end
end
