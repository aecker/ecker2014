%{
nc.Integers (manual) # List of integers

x   : int  # integer
---
%}

classdef Integers < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.Integers');
    end
end
