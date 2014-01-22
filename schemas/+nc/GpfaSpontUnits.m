%{
nc.GpfaSpontUnits (computed) # Units used for GPFA model

-> nc.GpfaSpontSet
-> ephys.Spikes
---
spont_rate : double # spontaneous firing rate (spikes/s)
%}

classdef GpfaSpontUnits < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.GpfaSpontUnits');
    end
end
