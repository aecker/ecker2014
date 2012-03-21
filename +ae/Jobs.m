%{
ae.Jobs (computed)   # jobs
-> ephys.SpikeSet
<<JobFields>>
%}

classdef Jobs < dj.Relvar
    properties(Constant)
        table = dj.Table('ae.Jobs')
    end
    methods
        function self = Jobs(varargin)
            self.restrict(varargin)
        end
    end
end
