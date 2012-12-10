%{
nc.GpfaParams (manual) # GPFA model parameters

bin_size    : int unsigned      # bin size (ms)
---
%}

classdef GpfaParams < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.GpfaParams');
    end
end
