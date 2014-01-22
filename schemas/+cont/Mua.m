%{
cont.Mua (imported) # mua (energy in 600-6K band) trace

->acq.Ephys
---
mua_file : VARCHAR(255) # name of file containg MUA
%}

classdef Mua < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('cont.Mua');
        popRel = acq.Ephys;
    end
    
    methods 
        function self = Mua(varargin)
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
                    tuple.mua_file = to(RawPathMap, [ephysFolder '/lfp/mua%d'], '/processed');
                    outFile = getLocalPath(tuple.mua_file);
                    mkdir(fileparts(outFile))
                    sourceFile = findFile(RawPathMap, sourceFile);
                    extractMuaTetrodes(sourceFile, outFile)
                otherwise
                    error('Not implemented yet')
            end
            self.insert(tuple);
        end
    end
end
