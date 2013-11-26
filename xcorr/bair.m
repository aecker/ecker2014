% Example of where Bair's method of integrating cross- and
% auto-correlograms to compute r_CCG(tau) fails because integral of
% auto-correlogram becomes negative.
%
% AE 2013-10-31

dt = -300 : 300;
K = 0.12 * cos(dt / 4) .* exp(-dt .^ 2 / 50 ^ 2);
K(dt == 0) = 1;
[~, order] = sort(abs(dt));
subplot(211)
plot(dt, K, 'k')
subplot(212)
Kint = cumsum(K(order));
plot(dt(dt >= 0), Kint(1 : 2 : end), 'k', [0 dt(end)], [0 0], '--k')
