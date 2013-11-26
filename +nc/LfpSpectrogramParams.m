%{
nc.LfpSpectrogramParams (manual) # LFP spectrogram parameters

all_tt              : boolean       # use all tetrodes or only ones with SUA
num_blocks          : int           # number of blocks
---
%}

classdef LfpSpectrogramParams < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.LfpSpectrogramParams');
    end
end
