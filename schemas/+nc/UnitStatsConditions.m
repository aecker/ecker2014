%{
nc.UnitStatsConditions (computed) # stats for units by condition

-> nc.UnitStats
-> nc.GratingConditions
---
mean_rate_cond   : float    # average firing rate
mean_count_cond  : float    # mean spike count
var_cond         : float    # variance
fano_cond = NULL : float    # fano factor
%}

classdef UnitStatsConditions < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.UnitStatsConditions');
    end
    
    methods 
        function self = UnitStatsConditions(varargin)
            self.restrict(varargin{:})
        end
    end
end
