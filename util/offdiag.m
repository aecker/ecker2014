function x = offdiag(X)
% Returns off-diagonal terms of matrix X.
%   x = offdiag(X) returns the offdiagonal terms of X. X is assumed to be
%   symmetric and only the upper offdiagonal terms are returned.
%
% AE 2010-11-18

x = X(~tril(ones(size(X))));
