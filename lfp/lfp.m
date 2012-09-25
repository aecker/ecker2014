% Prelininary analysis of LFP properties
% AE 2012-09-25

hammer = -317e3 / 2^23;
blackrock = -0.25;
neuralynx = -1e6 / 3000 / 2^11;

subjectIds = [23 8 9 11];
gains = [neuralynx, hammer, blackrock, blackrock];

restrictions = {'sort_method_num = 5', ...
                'bin_size = 50', ...
                'reg_val = 0', ...
                'min_rate = 0', ...
                'method = "net"', ...
                'rate > 1'};
restrictions = [sprintf('%s AND ', restrictions{:}) 'true'];

% LFPs were not converted to muV yet -- this fixes it until the tables are
% repopulated
convertedLfpParam = sprintf(['(lfp_param * (' ...
    '(subject_id = 8) / %.16f + ' ...
    '(subject_id IN (9, 11)) / %.16f + ' ...
    '(subject_id = 23) / %.16f' ...
    ')) -> converted_lfp_param'], hammer, blackrock, neuralynx);


%% LFP variances
figure
bins = linspace(0, 500, 40);
for i = 1 : numel(subjectIds)
    subplot(2, 2, i)
    [lfp, w] = fetchn(nc.LnpModel2Cond(restrictions) & sprintf('subject_id = %d', subjectIds(i)), 'lfp_data', convertedLfpParam);
    s = cellfun(@(x) std(x(:)) * abs(gains(i)), lfp);
    hist(s, bins);
    title(sprintf('%s | mean = %.0f', fetch1(acq.Subjects(sprintf('subject_id = %d', subjectIds(i))), 'subject_name'), mean(s)))
    xlim([bins(1), bins(end)])
end


%% LFP power spectra
figure, hold all
subjectNames = cell(1, numel(subjectIds));
for i = 1 : numel(subjectIds)
    lfp = fetchn(nc.LnpModel2Cond(restrictions) & sprintf('subject_id = %d', subjectIds(i)), 'lfp_data');
    S = cellfun(@(x) mean(abs(fft(x(1:10, :))), 2) * abs(gains(i)), lfp, 'uniformoutput', false);
    S = [S{:}];
    plot(0:2:18, mean(S, 2))
    xlim([0 20])
    subjectNames{i} = fetch1(acq.Subjects(struct('subject_id', subjectIds(i))), 'subject_name');
end
legend(subjectNames)


