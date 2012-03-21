%{
ae.LfpFilter (lookup) # LFP filter lookup table

lfp_filter_num  : smallint unsigned     # filter number
-----
min_freq        : float                 # start of passband
max_freq        : float                 # end of passband
dont_care_width : float                 # width of dont care band (outside passband)
%}

classdef LfpFilter < dj.Relvar

	properties(Constant)
		table = dj.Table('ae.LfpFilter')
	end

	methods
		function self = LfpFilter(varargin)
			self.restrict(varargin)
		end
	end
end
