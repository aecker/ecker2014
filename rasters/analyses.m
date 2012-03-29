% Plot spike rasters
% AE 2012-03-29

stimKeys = fetch(ae.ProjectsStimulation('project_name = "NoiseCorrAnesthesia"'));

lfpFilterNum = fetch1(ae.LfpFilter('min_freq = -1 AND max_freq = -1'), 'lfp_filter_num');
sortMethodNum = fetch1(sort.Methods('sort_method_name = "TetrodesMoG"'), 'sort_method_num');

% plot rasters with LFP
plotRastersLFP(key(1), lfpFilterNum, sortMethodNum, 4, [1 20], [0 3000])
