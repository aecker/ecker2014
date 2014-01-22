function figS1_xcorr_fail
% Fig. S1: Example where Bair's method fails
%   Integrating both cross- and auto-correlograms to compute r_CCG(tau) can
%   fail unde some conditions because integral of auto-correlogram can be
%   negative.
%
% AE 2013-12-03

dt = -100 : 100;
K = 0.15 * cos(dt / 4) .* exp(-dt .^ 2 / 50 ^ 2);
K(dt == 0) = 1;
[~, order] = sort(abs(dt));
Kint = cumsum(K(order));

fig = Figure(103, 'size', [100 100]);

subplot(2, 2, 1 : 2)
plot(dt, K, 'k')
xlabel('Time (a.u.)')
ylabel('Auto-correlation')

subplot(2, 2, 3)
plot(dt(dt >= 0), Kint(1 : 2 : end), 'k', [0 dt(end)], [0 0], '--k')
xlabel('Integration time (a.u.)')
ylabel('Cumulative auto-correlation')
axis square

subplot(2, 2, 4)
plot(sort(eig(toeplitz(ifftshift(K))), 'descend'), 'ok')
xlabel('Eigenvalue number')
ylabel('Eigenvalue')
axis square
set(gca, 'xscale', 'log', 'xlim', [0.5 200], 'xtick', 10 .^ (0 : 2))
set(gca, 'xticklabel', get(gca, 'xtick'))

fig.cleanup();

file = strrep(mfilename('fullpath'), 'code', 'figures');
fig.save(file)
