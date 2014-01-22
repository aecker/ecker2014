%{
ae.Lfp (computed) # Spike times organized by trials

-> ae.LfpSet
electrode_num       : tinyint unsigned  # electrode number
---
lfp                 : longblob          # LFP trace
lfp_sampling_rate   : double            # sampling rate
lfp_t0              : double            # time of first sample
%}

classdef Lfp < dj.Relvar
    properties (Constant)
        table = dj.Table('ae.Lfp');
    end
    
    methods 
        function makeTuples(self, key)
            
            % open LFP file
            lfpFile = fetch1(cont.Lfp & key, 'lfp_file');
            br = baseReader(getLocalPath(lfpFile), sprintf('t%d', key.electrode_num));
            Fs = getSamplingRate(br);
            lfp = br(:, 1);

            % Fill possible gaps in recordings on the Neuralynx system
            if isa(br, 'baseReaderMPI')
                [lfp, Fs] = fillNeuralynxGaps(lfp, br);
            end

            % determine resampling factors
            tol = 1e-8;  % looses at most 1 ms every 28h
            [p, q] = rat(2 * key.max_freq / Fs, tol);
            
            % design filter for lowpass & downsampling
            N = 10;  % filter order
            bta = 5; % design parameter for Kaiser window LPF
            fmax = key.max_freq / (Fs * p / 2);
            f = [0 fmax fmax 1];
            a = [1 1 0 0];
            L = 2 * N * q + 1;
            b = p * firls(L - 1, f, a) .* kaiser(L, bta)';
            lfp = resample(lfp, p, q, b);
            
            % highpass filter (using IIR for efficiency)
            if key.min_freq > 0
                fmin = key.min_freq / (Fs * p / q / 2);
                [b, a] = butter(3, fmin, 'high');
                lfp = filtfilt(b, a, lfp);
            end
            
            % fix sign flip in Neuralynx and Hammer files
            software = fetch1(acq.Sessions & key, 'recording_software');
            if any(strcmp(software, {'Neuralynx', 'Hammer'}))
                lfp = -lfp;
            end
            
            tuple = key;
            tuple.lfp = toMuV(br, lfp); % convert to muV
            tuple.lfp_t0 = br(1, 't');
            tuple.lfp_sampling_rate = 2 * key.max_freq;
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
