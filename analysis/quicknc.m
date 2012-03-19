function r = quicknc()

key.subject_id = 9;
key.sort_method_num = 2;

exclude = ephys.SingleUnit(key) & 'fp + fn > 0.05';
rel = nc.NoiseCorrelations(key) - (nc.UnitPairMembership & exclude);
r = fetchn(rel, 'r_noise_avg');
