% Processing my anesthetized noise correlation data
% AE 2012-02-14

restriction = 'subject_id in (8, 9, 11, 23) and sort_method_num = 5';

% create spike detection and sorting jobs
ephysKeys = fetch(acq.Ephys(restriction) & acq.EphysStimulationLink);
detectKeys = [];
for ephysKey = ephysKeys'
    detectKey = createDetectSet(ephysKey);
    createSortSet(detectKey);
end

% spike detection (on at-detect)
populate(detect.Sets, restriction);


%% Spike sorting (OLD WAY)
% automatic spike sorting (on HNL cluster -> mackey)
% /home/toliaslab/users/alex/projects/acq/processing/cluster/run

% % automatic sorting on local computer
% addpath ~/lab/projects/clustering
% run ~/lab/libraries/various/spider/use_spider.m
% matlabpool
% parfor i = 1:12
%     parPopulate(sort.TetrodesMoGAutomatic, sort.Jobs, subject)
% end
% matlabpool close
% 
% % manual spike sorting step
% sortKeys = fetch(sort.Sets(subject));
% manualSortDone(sortKeys(1), tetrodeNum, 'Comment')
% % ...
% 
% % finalize spike sorting
% populate(sort.TetrodesMoGFinalize, subject)
% populate(sort.SetsCompleted, subject)


%% Spike sorting Kalman filter model (NEW WAY)
% manually create sort.Params tuples and insert
populate(sort.Sets, 'sort_method_num = 5', restriction)

addpath ~/lab/libraries/various/mex_tt
matlabpool
parfor i = 1:12
    parPopulate(sort.KalmanAutomatic, sort.Jobs, restriction)
end
matlabpool close

% manual sorting
populate(sort.KalmanManual, restriction)

% finalize
populate(sort.KalmanFinalize, restriction)
populate(sort.SetsCompleted, restriction)
populate(ephys.SpikeSet, restriction)


%% Multi unit
% createSortSet(fetch(detect.Params(subject) - sort.Params('sort_method_num=4')), 'MultiUnit')
populate(sort.Sets, restriction)
populate(sort.MultiUnit, restriction)
populate(sort.SetsCompleted, restriction)
populate(ephys.SpikeSet, restriction)


%% Analysis tables

% stimulation
populate(stimulation.StimTrialGroup, restriction)
populate(nc.Gratings, restriction)

% spikes
populate(ephys.SpikeSet, restriction)

% pairs of neurons
populate(nc.UnitPairSet, restriction)


%% noise correlations
matlabpool
parfor i = 1:12
    parPopulate(ae.SpikeCountSet, ae.Jobs, restriction)
    parPopulate(ae.SpikesByTrialSet, ae.Jobs, restriction)
    parPopulate(nc.OriTuningSet, nc.Jobs, restriction)
    parPopulate(nc.NoiseCorrelationSet, nc.Jobs, restriction)
    parPopulate(nc.UnitStatsSet, nc.Jobs, restriction)
    parPopulate(nc.PairStatsSet, nc.Jobs, restriction)
end
matlabpool close

% stimulus

%%
populate(ae.LfpByTrialSet, restriction)
