% PSTH basis set based on PCA.
%   Performs PCA on the PSTHs or log-PSTHS. This table needs to be manually
%   deleted and repopulated if sessions are to be added to the pool.
%
% AE 2012-05-03

%{
nc.PsthBasis (computed) # Basis set for PSTHs based on PCA

-> nc.PsthParams
use_log             : boolean       # use log-PSTH?
---
psth_eigenvectors   : longblob      # eigenvectors
psth_eigenvalues    : longblob      # eigenvalues
%}

classdef PsthBasis < dj.Relvar & dj.AutoPopulate
    properties (Constant)
        table = dj.Table('nc.PsthBasis');
        popRel = nc.PsthParams;
    end
    
    methods 
        function self = PsthBasis(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            % check if all PSTHs are populated
            stimSessions = ae.ProjectsStimulation('project_name = "NoiseCorrAnesthesia"');
            psthSets = nc.PsthSet(key) & 'sort_method_num = 2'; % single units
            if count(stimSessions - psthSets) ...
                && ~strncmpi('y', input('Not all PSTHs are populated. Continue?\n[y/n] > ', 's'), 1)
                return
            end
            
            % obtain PSTHs
            psths = fetchn(psthSets * nc.Psth, 'psth');
            nBins = min(fetchn(stimSessions * nc.Gratings, 'stimulus_time')) / key.bin_size;
            psths = cellfun(@(x) x(1 : nBins, :), psths, 'UniformOutput', false);
            psths = [psths{:}]';
            
            for useLog = [false true]
                
                % log transform (set minimum baseline to avoid outliers with
                % large negative logs when cells fire few spikes)
                if useLog
                    base = log(key.bin_size / 1000);  % mininum: 1 spike/s
                    X = log(psths);
                    X(X < base) = base;
                else
                    X = psths;
                end
                
                % subtract temporal mean from each PSTH (we're interested in
                % the temporal dynamics, not the absolute level
                X = bsxfun(@minus, X, mean(X, 2));
                
                % PCA
                [V, D] = eig(cov(X));
                
                % insert into db
                tuple = key;
                tuple.use_log = useLog;
                tuple.psth_eigenvectors = fliplr(V);
                tuple.psth_eigenvalues = flipud(diag(D));
                self.insert(tuple);
                
                % insert used PSTH sets into membership table
                tuples = fetch(psthSets);
                [tuples.use_log] = deal(useLog);
                insert(nc.PsthBasisMembership, tuples);
            end
        end
    end
end
