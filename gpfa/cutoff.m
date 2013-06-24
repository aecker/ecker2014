%% Calculate cutoff frequency for Gaussian kernel
% AE 2013-06-21

tau = 243;  % average in anesthetized data
Fs = 100;
t = -1000 : (1000 / Fs) : 1000;
b = exp(-t .^ 2 / tau ^ 2 / 2);
fvtool(b / sum(b), 1, 'Fs', Fs)
axis([0 10 -100 5])
