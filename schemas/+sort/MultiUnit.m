%{
sort.MultiUnit (imported) # provide transparent access to multi unit

->sort.Electrodes
---
%}

classdef MultiUnit < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('sort.MultiUnit');
        popRel = sort.Electrodes * sort.Methods('sort_method_name = "MultiUnit"');
    end
    
    methods 
        function self = MultiUnit(varargin)
            self.restrict(varargin{:})
        end
            
        function [spikeTimes, waveform, spikeFile] = getSpikes(self)
            assert(count(self) == 1, 'Relvar must be scalar!');
            spikeFile = fetch1(detect.Electrodes * self, 'detect_electrode_file');
            tt = ah_readTetData(getLocalPath(spikeFile));
            waveform = cell2mat(cellfun(@(x) mean(x, 2), tt.w, 'UniformOutput', false));
            spikeTimes = tt.t;
        end
    end
    
    methods (Access=protected)       
        function makeTuples(self, key)
            self.insert(key);
        end
    end
end
