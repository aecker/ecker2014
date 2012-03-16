function r = quicknc()

subject.subject_id = 9;
stimKeys = fetch(nc.Gratings(subject) & nc.SpikeCountSet);
for stimKey = stimKeys'
    condKeys = fetch(nc.GratingConditions(stimKey));
    nCond = numel(condKeys);
    excludeKeys = fetch(ephys.SingleUnit(subject) & 'fp + fn > 0.1' & nc.SpikeCountSet(stimKey));
    pairKeys = fetch(nc.UnitPairs(stimKey) - (nc.UnitPairMembership & excludeKeys));
    nPairs = numel(pairKeys);
    r = zeros(nPairs, nCond);
    for i = 1:nCond
        unitKeys = fetch(ephys.SingleUnit(subject) & (nc.UnitPairMembership * nc.UnitPairs(pairKeys)));
        nUnits = numel(unitKeys);
        x = zeros(100, nUnits);
        for j = 1:nUnits
            x(:,j) = fetchn(nc.SpikeCounts(unitKeys(j)) & nc.GratingTrials(condKeys(i)), 'spike_count');
        end
        R = corrcoef(x);
        r(:,i) = R(~tril(ones(nUnits)));
    end
end



