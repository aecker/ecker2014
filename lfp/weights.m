
subjectIds = [23 8 9 11];
restrictions = {'sort_method_num = 5', ...
                'bin_size = 50', ...
                'reg_val = 0', ...
                'min_rate = 0', ...
                'method = "net"', ...
                'rate > 1'};
restrictions = [sprintf('%s AND ', restrictions{:}) 'true'];

% LFPs were not converted to muV yet -- this fixes it until the tables are
% repopulated
hammer = -317e3 / 2^23;
blackrock = -0.25;
neuralynx = -1e6 / 3000 / 2^11;
convertedLfpParam = sprintf(['(lfp_param * (' ...
    '(subject_id = 8) / %.16f + ' ...
    '(subject_id IN (9, 11)) / %.16f + ' ...
    '(subject_id = 23) / %.16f' ...
    ')) -> converted_lfp_param'], hammer, blackrock, neuralynx);

         
%% Histogram of weights
xl = 0.02;
figure(1), clf
for i = 1 : 4
    subplot(2, 2, i)
    w = fetchn(nc.LnpModel2Cond(restrictions) & struct('subject_id', subjectIds(i)), convertedLfpParam);
    w(abs(w) > 1 | isnan(w)) = [];
    hist(w, linspace(-xl, xl, 40))
    xlim([-xl xl])
    title(sprintf('%s | median = %e', fetch1(acq.Subjects(struct('subject_id', subjectIds(i))), 'subject_name'), median(w)))
end


%% Dependence of weights on firing rate
figure(5), clf, hold all
b = 0 : 0.25 : 2.5;
subjectNames = cell(1, numel(subjectIds));
for i = 1 : 4
    [r, w] = fetchn(nc.LnpModel2Cond(restrictions) & struct('subject_id', subjectIds(i)), 'rate', convertedLfpParam);
    [counts, bin] = histc(log10(r), b);
    wm = accumarray(bin, w, [numel(b), 1], @mean);
    wm(counts < 5) = NaN;
    wse = accumarray(bin, w, [numel(b), 1], @(x) std(x) / sqrt(numel(x)));
    errorbar(b + diff(b(1 : 2)) / 2, wm, wse, '.-')
    % plot(b + diff(b(1 : 2)) / 2, wm, '.-')
    subjectNames{i} = fetch1(acq.Subjects(struct('subject_id', subjectIds(i))), 'subject_name');
    set(gca, 'xlim', b([1 end]), 'xticklabel', fix(round(10 .^ get(gca, 'xtick') * 100)) / 100)
    xlabel('Firing rate (spikes/s)')
    ylabel('LFP weight')
end
legend(subjectNames)


%% MODEL 3
xl = 0.02;
figure(3), clf
for i = 1 : 4
    w = fetchn(nc.LnpModel3('min_freq = 0') & ephys.Spikes & ...
        struct('subject_id', subjectIds(i)) & ...
        nc.LnpModel3Spikes('mean_rate > 5'), 'lfp_param');
    subplot(2, 2, i)
    hist(w, linspace(-xl, xl, 40))
    xlim([-xl xl])
    title(sprintf('%s | median = %e', fetch1(acq.Subjects(struct('subject_id', subjectIds(i))), 'subject_name'), median(w)))
end

