%{
nc.GpfaParams (computed) # GPFA model parameters

latent_dim  : tinyint unsigned  # number of latent dimensions
bin_size    : int unsigned      # bin size (ms)
---
%}

classdef GpfaParams < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.GpfaParams');
    end
end
