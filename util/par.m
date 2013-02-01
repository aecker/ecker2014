function y = par(x, varargin)
% Parenthesis operator.
%   y = par(x, i, j) is the same as x(i, j)
%
% AE 2013-01-31

y = x(varargin{:});
