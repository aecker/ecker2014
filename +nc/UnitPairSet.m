%{
nc.UnitPairSet (computed) # Set of all pairs of units for one recording

-> ephys.SpikeSet
---
%}

classdef UnitPairSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.UnitPairSet');
        popRel = ephys.SpikeSet;
    end
    
    methods 
        function self = UnitPairSet(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(this, key)
            insert(this, key);
            units = fetch(ephys.Spikes(key));
            n = numel(units);
            pair = key;
            pair.pair_num = 1;
            for i = 1:n
                for j = i+1:n
                    insert(nc.UnitPairs, pair);
                    member = pair;
                    member.unit_id = units(i).unit_id;
                    insert(nc.UnitPairMembership, member);
                    member.unit_id = units(j).unit_id;
                    insert(nc.UnitPairMembership, member);
                    pair.pair_num = pair.pair_num + 1;
                end
            end
        end
    end
end
