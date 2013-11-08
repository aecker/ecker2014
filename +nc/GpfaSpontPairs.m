%{
nc.GpfaSpontPairs (computed) # Pairs used for GPFA model

-> nc.GpfaSpontSet
-> nc.UnitPairs
---
index_i     : int unsigned  # row index in covariance matrix
index_j     : int unsigned  # column index in covariance matrix
%}

classdef GpfaSpontPairs < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.GpfaSpontPairs');
    end
end
