% Code for populating database tables.
%
%   This script won't run as is, since certain steps (e.g. spike detection)
%   were run on dedicated computers. Also, some of the analyses require
%   lots of CPU usage and memory and were run on a compute cluster.
%
% AE 2013-01-22


%% Initial data processing (spike detection & extraction)
sorting = sort.Methods & 'sort_method_name = "MoKsm"';

% create spike detection and sorting jobs
ephysKeys = fetch(acq.Ephys & (acq.EphysStimulationLink & nc.Gratings & nc.Anesthesia));
detectKeys = [];
for ephysKey = ephysKeys'
    detectKey = createDetectSet(ephysKey);
    createSortSet(detectKey);
end

% spike detection
populate(detect.Sets, ephysKeys, sorting);


%% Spike sorting using Kalman filter model
restriction = {nc.Anesthesia, sorting};

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
restriction = nc.Anesthesia;

populate(stimulation.StimTrialGroup, restriction)
populate(nc.Gratings, restriction)


%% Noise correlations etc.
restriction = {nc.Anesthesia, sorting};

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

