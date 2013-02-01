function y = curly(x, varargin)
% Curly braces operator.
%   y = curly(x, i, j) is the same as x{i, j}
%
% AE 2013-01-31

y = x{varargin{:}};
