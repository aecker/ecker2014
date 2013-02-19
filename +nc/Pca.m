%{
nc.Pca (computed) # PCA on spike counts

-> ae.SpikeCountSet
-> nc.Gratings
-> nc.PcaParams
---
first_pc            : blob          # 1st PC
second_pc           : blob          # 2nd PC
all_pc              : blob          # all PCs
first_timecourse    : mediumblob    # timecourse of first PC
second_timecourse   : mediumblob    # timecourse of second PC
all_timecourse      : mediumblob    # timecourse of all PCs
first_ev            : double        # largest eigenvalue
second_ev           : double        # second largest eigenvalue
spectrum            : blob          # all eigenvalues
first_ev_rel        : double        # largest eigenvalue percent var
second_ev_rel       : double        # second largest eigenvalue percent var
spectrum_rel        : blob          # all eigenvalue percent var
%}

classdef Pca < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.Pca');
        popRel = ae.SpikeCountSet * nc.PcaParams;
    end
    
    methods 
        function self = Pca(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access = protected)
        function makeTuples(self, key)
            
            % remove unstable cells
            unitKey = sprintf('stability < %f', key.min_stability);
            nUnits = count(nc.UnitStats & key & unitKey);
            nCond = count(nc.GratingConditions & key);
            
            % get spike counts for all conditions and convert to z-scores
            Y = zeros(0, nUnits);
            for iCond = 1 : nCond
                s = fetchn(ae.SpikeCounts * nc.GratingTrials * nc.UnitStats ...
                    & key & struct('condition_num', iCond) & unitKey, ...
                    'spike_count', 'ORDER BY unit_id, trial_num');
                s = zscore(reshape(s, [], nUnits));
                Y = [Y; s];  %#ok

                % by condition
                [V, T, lambda] = princomp(s);
                tuple = key;
                tuple.condition_num = iCond;
                tuple.first_pc = V(:, 1);
                tuple.second_pc = V(:, 2);
                tuple.all_pc = V;
                tuple.first_timecourse = T(:, 1);
                tuple.second_timecourse = T(:, 2);
                tuple.all_timecourse = T;
                tuple.first_ev = lambda(1);
                tuple.second_ev = lambda(2);
                tuple.spectrum = lambda;
                tuple.first_ev_rel = lambda(1) / sum(lambda);
                tuple.second_ev_rel = lambda(2) / sum(lambda);
                tuple.spectrum_rel = lambda / sum(lambda);
                byCond(iCond) = tuple; %#ok
            end
            
            [V, T, lambda] = princomp(Y);
            tuple = key;
            tuple.first_pc = V(:, 1);
            tuple.second_pc = V(:, 2);
            tuple.all_pc = V;
            tuple.first_timecourse = T(:, 1);
            tuple.second_timecourse = T(:, 2);
            tuple.all_timecourse = T;
            tuple.first_ev = lambda(1);
            tuple.second_ev = lambda(2);
            tuple.spectrum = lambda;
            tuple.first_ev_rel = lambda(1) / sum(lambda);
            tuple.second_ev_rel = lambda(2) / sum(lambda);
            tuple.spectrum_rel = lambda / sum(lambda);
            self.insert(tuple);
            
            insert(nc.PcaCond, byCond);
        end
    end
end
