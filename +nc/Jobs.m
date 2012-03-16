%{
nc.Jobs (computed)   # noise correlation jobs
-> ephys.SpikeSet
<<JobFields>>
%}

classdef Jobs < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.Jobs')
    end
    methods
        function self = Jobs(varargin)
            self.restrict(varargin)
        end
    end
end
