%{
nc.GpfaPairs (computed) # Pairs used for GPFA model

-> nc.GpfaModelSet
-> nc.UnitPairs
---
index_i     : int unsigned  # row index in covariance matrix
index_j     : int unsigned  # column index in covariance matrix
%}

classdef GpfaPairs < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.GpfaPairs');
    end

    methods
        function self = GpfaPairs(varargin)
            self.restrict(varargin{:})
        end
    end
end
