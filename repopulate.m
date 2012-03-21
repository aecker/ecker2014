% Processing my anesthetized noise correlation data
% AE 2012-02-14

subject = 'subject_id = 11';

% create spike detection and sorting jobs
ephysKeys = fetch(acq.Ephys(subject) & acq.EphysStimulationLink);
detectKeys = [];
for ephysKey = ephysKeys'
    detectKey = createDetectSet(ephysKey);
    createSortSet(detectKey);
end

% spike detection (on at-detect)
populate(detect.Sets, subject);


%% Spike sorting
% automatic spike sorting (on HNL cluster -> mackey)
% /home/toliaslab/users/alex/projects/acq/processing/cluster/run

% automatic sorting on local computer
addpath ~/lab/projects/clustering
run ~/lab/libraries/various/spider/use_spider.m
matlabpool
parfor i = 1:12
    parPopulate(sort.TetrodesMoGAutomatic, sort.Jobs, subject)
end
matlabpool close


%%

% manual spike sorting step
sortKeys = fetch(sort.Sets(subject));
manualSortDone(sortKeys(1), tetrodeNum, 'Comment')
% ...

% finalize spike sorting
populate(sort.TetrodesMoGFinalize, subject)
populate(sort.SetsCompleted, subject)


%% Multi unit
% createSortSet(fetch(detect.Params(subject) - sort.Params('sort_method_num=4')), 'MultiUnit')
populate(sort.Sets, subject)
populate(sort.MultiUnit, subject)
populate(sort.SetsCompleted, subject)
populate(ephys.SpikeSet, subject)


%% Analysis tables

% stimulation
populate(stimulation.StimTrialGroup, subject)
populate(nc.Gratings, subject)

% spikes
populate(ephys.SpikeSet, subject)

% pairs of neurons
populate(nc.UnitPairSet, subject)


%% noise correlations
matlabpool
parfor i = 1:12
    parPopulate(ae.SpikeCountSet, ae.Jobs, subject)
    parPopulate(ae.SpikesByTrialSet, ae.Jobs, subject)
%     parPopulate(ae.LfpByTrialSet, ae.Jobs, subject)
    parPopulate(nc.NoiseCorrelationSet, nc.Jobs, subject)
end
matlabpool close

% stimulus

