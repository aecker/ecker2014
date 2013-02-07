function findSite(transformNum, zscore, byTrial)
% Find a site with a strong effect
%
% AE 2013-01-09

restrictions = {'subject_id in (9, 11) AND sort_method_num = 5 AND kfold_cv = 2', ...
                 struct('transform_num', transformNum, 'zscore', zscore, 'by_trial', byTrial)};

counts = pro(nc.GpfaModelSet, nc.GpfaUnits, 'count(1) -> n');
rel = (nc.GpfaParams * nc.GpfaCovExpl * counts) & restrictions & 'latent_dim in (0, 1) AND n >= 20';
data = fetch(rel, '*');
n = numel(data);
data = dj.struct.sort(data, {'latent_dim', 'cv_run', 'stim_start_time'});
data = reshape(data, [n / 4, 2, 2]);

convert = @(C) C ./ sqrt(diag(C) * diag(C)');

% residual cov/corr
[red, units] = collect(data, @(data) convert(data.cov_resid_test));


[~, order] = sort(max(red, [], 2));


1;



function [red, units] = collect(data, fun)

offdiag = @(x) x(~tril(ones(size(x))));
[n, kfold, pmax] = size(data);
red = zeros(n, kfold);
units = zeros(n, 1);
for i = 1 : n
    for k = 1 : kfold
        D = fun(data(i, k, 1)) - fun(data(i, k, 2));
        red(i, k) = mean(offdiag(D));
    end
    units(i) = size(D, 1);
end
