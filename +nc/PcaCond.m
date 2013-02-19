%{
nc.PcaCond (computed) # PCA on spike counts

-> nc.Pca
-> nc.GratingConditions
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

classdef PcaCond < dj.Relvar
    properties(Constant)
        table = dj.Table('nc.PcaCond');
    end
    
    methods 
        function self = PcaCond(varargin)
            self.restrict(varargin{:})
        end
    end
end
