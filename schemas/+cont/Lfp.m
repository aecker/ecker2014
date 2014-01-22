%{
cont.Lfp (imported) # local field potential trace

->acq.Ephys
---
lfp_file : VARCHAR(255) # name of file containg LFP
%}

classdef Lfp < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('cont.Lfp');
        popRel = acq.Ephys;
    end
    
    methods 
        function self = Lfp(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access=protected)
        function makeTuples(self, key)
            tuple = key;
            switch fetch1(acq.Ephys(key) * acq.EphysTypes, 'ephys_type')
                case 'Tetrodes'
                    sourceFile = fetch1(acq.Ephys(key), 'ephys_path');
                    ephysFolder = fileparts(sourceFile);
                    tuple.lfp_file = to(RawPathMap, [ephysFolder '/lfp/lfp%d'], '/processed');
                    outFile = getLocalPath(tuple.lfp_file);
                    mkdir(fileparts(outFile))
                    sourceFile = findFile(RawPathMap, sourceFile);
                    extractLfpTetrodes(sourceFile, outFile)
                otherwise
                    error('Not implemented yet')
            end
            self.insert(tuple);
        end
    end
end
