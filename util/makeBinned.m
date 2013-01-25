function [varargout] = makeBinned(x, y, bins, varargin)
% Bin and average scatter plot.
%   [out1, out2, ..., binc] = makeBinned(x, y, bins, fun1, fun2) bins the
%   data according to x and the bin edges defined by bins, then applies
%   fun(y) to all values in a given bin [bins_i, bins_i+1). The k^th output
%   contain the result of the k^th fun(y) for each bin. The optional last
%   output binc contains the bin centers.
%
%   [...] = makeBinned(..., outliers) specifies how to deal with outliers
%   outside the range spanned by the bins. If outliers is set to 'ignore'
%   they are simply ignored. If set to 'include' they are included in the
%   left- and right-most bins, respectively. If ommitted or set to 'error'
%   an error is thrown.
%
% AE 2013-01-23

% deal with outliers
if isempty(varargin) || ~ischar(varargin{end})
    outliers = 'error';
else
    outliers = varargin{end};
    varargin(end) = [];
end
switch outliers
    case 'ignore'
        ndx = x >= bins(1) & x < bins(end);
        x = x(ndx);
        y = y(ndx);
    case 'include'
        x(x < bins(1)) = bins(1);
        x(x >= bins(end)) = (bins(end - 1) + bins(end)) / 2;
    otherwise
        assert(all(x >= bins(1) & x < bins(end)), 'bins must cover the full range of x values [%f, %f]!', min(x), max(x))
end

nFun = numel(varargin);
bins = bins(:);
[~, bin] = histc(x, bins);
varargout = cell(1, nargout);
for k = 1 : nFun
    out = accumarray(bin, y, [numel(bins) 1], varargin{k}, varargin{k}([]));
    varargout{k} = out(1 : end - 1);
end
if nFun < nargout
    varargout{nFun + 1} = mean([bins(1 : end - 1), bins(2 : end)], 2);
end
