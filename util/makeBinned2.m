function [varargout] = makeBinned2(i, j, z, ibins, jbins, varargin)
% Bin and average scatter plot.
%   [out1, ..., xbinc, ybinc] = makeBinned(x, y, z, xbins, ybins, fun1,
%   ...) bins the data according to (x, y) and the bin edges defined by
%   xbins and ybins, then applies fun(z) to all values in a given bin. The
%   output is a matrix of size (#ybins, #xbins), where each entry contains
%   the result of fun(z) for the corresponding bin. The optional last two
%   outputs xbinc and ybinc contain the bin centers.
%
%   [...] = makeBinned(..., outliers) specifies how to deal with outliers
%   outside the range spanned by the bins. If outliers is set to 'ignore'
%   they are simply ignored. If set to 'include' they are included in the
%   left- and right-most bins, respectively. If ommitted or set to 'error'
%   an error is thrown.
%
% AE 2013-05-23

% deal with outliers
if isempty(varargin) || ~ischar(varargin{end})
    outliers = 'error';
else
    outliers = varargin{end};
    varargin(end) = [];
end
switch outliers
    case 'ignore'
        ndx = i >= ibins(1) & i < ibins(end) & j > jbins(1) & j < jbins(end);
        i = i(ndx);
        j = j(ndx);
        z = z(ndx);
    case 'include'
        i(i < ibins(1)) = ibins(1);
        i(i >= ibins(end)) = (ibins(end - 1) + ibins(end)) / 2;
        j(j < jbins(1)) = jbins(1);
        j(j >= jbins(end)) = (jbins(end - 1) + jbins(end)) / 2;
    otherwise
        assert(all(i >= ibins(1) & i < ibins(end) & j > jbins(1) & j < jbins(end)), ...
            'bins must cover the full range of (x, y) values ([%f, %f], [%f, %f])!', min(i), max(i), min(j), max(j))
end

ibins = ibins(:);
[~, bini] = histc(i, ibins);
jbins = jbins(:);
[~, binj] = histc(j, jbins);
nFun = numel(varargin);
varargout = cell(1, nargout);
for k = 1 : nFun
    out = accumarray([bini(:), binj(:)], z, [numel(ibins) numel(jbins)], varargin{k}, varargin{k}([]));
    varargout{k} = out(1 : end - 1, 1 : end - 1);
end
if nFun < nargout
    varargout{nFun + 1} = mean([ibins(1 : end - 1), ibins(2 : end)], 2);
    varargout{nFun + 2} = mean([jbins(1 : end - 1), jbins(2 : end)], 2);
end
