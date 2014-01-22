% Code for populating database tables.
%
%   This script won't run as is, since certain steps (e.g. spike detection)
%   were run on dedicated computers. Also, some of the analyses require
%   lots of CPU usage and memory and were run on a compute cluster.
%
% AE 2013-01-22


% Subjects and parameters for data processing
restriction = 'subject_id in (8, 9, 11, 23) AND detect_method_num = 4 AND sort_method_num = 5';


%% Initial data processing (spike detection & extraction)

% create spike detection and sorting jobs
ephysKeys = fetch(acq.Ephys & acq.EphysStimulationLink & restriction);
detectKeys = [];
for ephysKey = ephysKeys'
    detectKey = createDetectSet(ephysKey);
    createSortSet(detectKey);
end

% spike detection
populate(detect.Sets, restriction);


%% Spike sorting using Kalman filter model

% automatic step
populate(sort.Sets, restriction)
addpath ~/lab/libraries/various/mex_tt  % needed only for old MPI data
matlabpool
parfor i = 1 : 12
    parpopulate(sort.KalmanAutomatic, restriction)
end
matlabpool close

% manual verification step
populate(sort.KalmanManual, restriction)

% finalize
populate(sort.KalmanFinalize, restriction)
populate(sort.SetsCompleted, restriction)
populate(ephys.SpikeSet, restriction)


%% Visual stimulation

populate(stimulation.StimTrialGroup, restriction)
populate(nc.Gratings, restriction)


%% Noise correlations etc.

populate(nc.UnitPairSet, restriction)
matlabpool
parfor i = 1 : 12
    parpopulate(ae.SpikeCountSet, restriction)
    parpopulate(ae.SpikesByTrialSet, restriction)
    parpopulate(nc.OriTuningSet, restriction)
    parpopulate(nc.UnitStatsSet, restriction)
    parpopulate(nc.NoiseCorrelationSet, restriction)
end
matlabpool close

