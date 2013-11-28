function noiseCorrForGpfaPairs(varargin)
% Noise correlations only for those pairs/conditions used in GPFA analysis.
% AE 2012-12-19

if ~nargin
    restrictions = {'subject_id in (9, 11)', ...
                    'sort_method_num = 5', ...
                    'spike_count_end = 2000'};
else
    restrictions = varargin;
end

excludePairs = (nc.UnitPairMembership * nc.GratingConditions * ...
    acq.EphysStimulationLink * ephys.Spikes) - nc.GpfaUnits;
noiseCorr = ((nc.NoiseCorrelationConditions * nc.UnitPairs * ...
    acq.EphysStimulationLink * nc.GratingConditions)) - excludePairs;

r = fetchn(noiseCorr & restrictions, 'r_noise_cond');

hist(r, 100)
xlabel('Noise correlation')
ylabel('# pairs * conditions')
set(gca, 'box', 'off')
