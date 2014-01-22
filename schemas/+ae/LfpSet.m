%{
ae.LfpSet (imported) # LFP

-> ae.LfpParams
-> cont.Lfp
---
%}

classdef LfpSet < dj.Relvar & dj.AutoPopulate
    properties (Constant)
        table = dj.Table('ae.LfpSet');
        popRel = cont.Lfp * ae.LfpParams & 'max_freq <= 100';
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            if key.setup ~= 99
                lfpFile = fetch1(cont.Lfp & key, 'lfp_file');
                br = baseReader(getLocalPath(lfpFile));
                channelNames = getChannelNames(br);
                electrodes = regexp(channelNames, '\w(\d+)*', 'tokens', 'once');
                electrodes = cellfun(@(x) str2double(x{1}), electrodes(:));
            else
                electrodes = 3 : 10;  % set electroees manually for old MPI data
            end
            self.insert(key);
            for e = electrodes(:)'
                eKey = key;
                eKey.electrode_num = e;
                makeTuples(ae.Lfp, eKey);
            end
        end
    end
end
