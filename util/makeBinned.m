function [varargout] = makeBinned(x, y, bins, varargin)
% Bin and average scatter plot.
%   [out1, out2, ..., binc] = makeBinned(x, y, bins, fun1, fun2) bins the
%   data according to x and the bin edges defined by bins, then applies
%   fun(y) to all values in a given bin [bins_i, bins_i+1). The k^th output
%   contain the result of the k^th fun(y) for each bin. The optional last
%   output binc contains the bin centers.
%
% AE 2013-01-23

assert(all(x >= bins(1) & x < bins(end)), 'bins must cover the full range of x values [%f, %f]!', min(x), max(x))
nFun = numel(varargin);
bins = bins(:)';
[~, bin] = histc(x, bins);
varargout = cell(1, nargout);
for k = 1 : nFun
    out = accumarray(bin, y, [numel(bins) 1], varargin{k});
    varargout{k} = out(1 : end - 1);
end
if nFun < nargout
    varargout{nFun + 1} = mean([bins(1 : end - 1); bins(2 : end)], 1);
end
