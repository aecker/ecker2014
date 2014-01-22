%{
ae.TetrodeImplantsEphysLink (manual) # maps tetrode implants to ephys recordings

-> acq.Ephys
-> ae.TetrodeImplants
---
%}

classdef TetrodeImplantsEphysLink < dj.Relvar
    properties (Constant)
        table = dj.Table('ae.TetrodeImplantsEphysLink');
    end
end
