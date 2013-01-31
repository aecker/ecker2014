%{
nc.LfpPowerRatioSet (imported) # LFP

-> nc.LfpPowerRatioParams
-> cont.Lfp
---
%}

classdef LfpPowerRatioSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.LfpPowerRatioSet');
        popRel = cont.Lfp * nc.LfpPowerRatioParams;
    end
    
    methods
        function self = LfpPowerRatioSet(varargin)
            self.restrict(varargin{:})
        end
    end

    methods(Access = protected)
        function makeTuples(self, key)
            if key.setup ~= 99
                lfpFile = fetch1(cont.Lfp(key), 'lfp_file');
                br = baseReader(getLocalPath(lfpFile));
                channelNames = getChannelNames(br);
                electrodes = regexp(channelNames, '\w(\d+)*', 'tokens', 'once');
                electrodes = cellfun(@(x) str2double(x{1}), electrodes(:));
            else
                electrodes = 3 : 10;  % set electrodes manually for old MPI data
            end
            self.insert(key);
            for e = electrodes(:)'
                eKey = key;
                eKey.electrode_num = e;
                makeTuples(nc.LfpPowerRatio, eKey);
            end
        end
    end
end
