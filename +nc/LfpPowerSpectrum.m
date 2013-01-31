%{
nc.LfpPowerSpectrum (computed) # LFP power spectrum

-> nc.LfpPowerSpectrumSet
electrode_num   : tinyint unsigned  # electrode number
---
power_spectrum  : mediumblob        # LFP power spectrum
frequencies     : mediumblob        # power spectrum frequencies
%}

classdef LfpPowerSpectrum < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.LfpPowerSpectrum');
    end
    
    methods 
        function self = LfpPowerSpectrum(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            
            % open LFP file
            lfpFile = fetch1(cont.Lfp(key), 'lfp_file');
            br = baseReader(getLocalPath(lfpFile), sprintf('t%d', key.electrode_num));
            Fs = getSamplingRate(br);
            lfp = br(:, 1);

            % Fill possible gaps in recordings on the Neuralynx system
            if isa(br, 'baseReaderMPI')
                [lfp, Fs] = fillNeuralynxGaps(lfp, br);
            end

            % compute power ratio
            window = 2 ^ round(log2(30 * Fs));  % ca. 30 sec
            fmax = 250;                         % max. frequency for LFP
            [Pxx, w] = pwelch(lfp, window);
            f = w / (2 * pi) * Fs;
            tuple = key;
            tuple.power_spectrum = Pxx(f < fmax);
            tuple.frequencies = f(f < fmax);
            insert(self, tuple);
        end
    end
end

function [lfp, Fs] = fillNeuralynxGaps(lfp, br)
% Fill gaps in recordings by linearly interpolating between the two samples
% that are spaced by more than one sampling period. The algorithm therefore
% possibly shifts each sample by half a sampling period. If multiple gaps
% are filled we make sure that the total shift of each sample remains
% within half a sampling period.
%
% In addition, the sampling rate stored in the file isn't sufficiently
% accurate to store only t0. This function returns a more accurate
% estimate.

t = br(:, 't');
dt = diff(t);
d = mean(dt(dt < 1.5 * median(dt)));
Fs = 1000 / d;
ndx = find(dt > 1.5 * d);
if ~isempty(ndx)
    r = 0;
    for i = numel(ndx) : -1 : 1
        nex = diff(t(ndx(i) : ndx(i) + 1)) / d - r;
        n = round(nex);
        r = n - nex;
        lfp = [lfp(1 : ndx(i) - 1); ...
            linspace(lfp(ndx(i)), lfp(ndx(i) + 1), n + 1)'; ...
            lfp(ndx(i) + 2 : end)];
    end
end
end
