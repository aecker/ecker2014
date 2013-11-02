function x = sample(K)
% Sample from stationary process with autocorrelation function K.
%   x = sample(K)

assert(isvector(K), 'K must be a vector!')
x = real(ifft(fft(randn(size(K))) .* sqrt(abs(fft(K)))));
