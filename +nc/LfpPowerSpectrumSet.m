%{
nc.LfpPowerSpectrumSet (imported) # LFP power spectrum

-> cont.Lfp
---
%}

classdef LfpPowerSpectrumSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.LfpPowerSpectrumSet');
        popRel = cont.Lfp;
    end
    
    methods
        function self = LfpPowerSpectrumSet(varargin)
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
                makeTuples(nc.LfpPowerSpectrum, eKey);
            end
        end
    end
end
