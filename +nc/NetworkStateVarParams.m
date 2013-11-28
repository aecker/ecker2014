%{
nc.NetworkStateVarParams (computed) # parameters

num_blocks      : int       # number of blocks
---
%}

classdef NetworkStateVarParams < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.NetworkStateVarParams');
    end
end
