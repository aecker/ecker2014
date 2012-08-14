% Noise correlations by sessions.
% AE 2012-03-16


%% get noise correlations by stim session
% key.subject_id = 11;
% key.sort_method_num = 2;
% key.spike_count_end = 2000;
% key = 'subject_id IN (9, 11) AND sort_method_num = 5 AND spike_count_end = 500';
key = struct('subject_id', {9 11}, 'sort_method_num', 5, 'spike_count_end', 500);
excludePairs = nc.UnitPairMembership(key) & ((ephys.SingleUnit(key) & 'fp + fn > 0.1') + (nc.UnitStats(key) & 'stability > 0.1'));
stimKeys = fetch(acq.Stimulation & nc.NoiseCorrelations(key));
n = numel(stimKeys);
rr = cell(1, n);
for i = 1:n
    rel = (nc.NoiseCorrelations(key) - excludePairs) & stimKeys(i);
    rr{i} = fetchn(rel, 'r_noise_avg');
end
    

%% plot histograms
figure(1), clf
bins = -0.2:0.1:0.7;
N = numel(rr);
for i = 1:N
    subplot(N, 1, i)
    h = hist(rr{i}, bins);
    bar(bins, h, 1, 'facecolor', 0.5 * ones(3, 1))
    set(gca, 'xlim', [-0.8 0.8], 'box', 'off')
    if i == N
        xlabel('Noise correlation')
    end
    ylabel('# of pairs')
    title(sprintf('avg = %.2f', mean(rr{i})))
end

