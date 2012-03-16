%{
nc.Gratings (computed) # Information specific to grating experiment

-> stimulation.StimTrialGroup
---
speed              : float # speed of moving gratings (0 if static)
location_x         : float # stimulus center (x coordinate in px)
location_y         : float # stimulus center (y coordinate in px)
spatial_freq       : float # spatial frequency
stimulus_time      : float # duration of stimulus in ms
post_stimulus_time : float # time monkey has to fixate after stimulus
%}

classdef Gratings < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.Gratings');
        popRel = stimulation.StimTrialGroup * ...
            acq.Stimulation('exp_type IN ("GratingExperiment", "AcuteGratingExperiment")');
    end
    
    methods 
        function self = Gratings(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(this, key)
            % Grating session
            tuple = key;
            rel = stimulation.StimTrialGroup(key);
            tuple.speed = getConstant(rel, 'speed');
            location = getConstant(rel, 'location', 'UniformOutput', false);
            tuple.location_x = location{1}(1);
            tuple.location_y = location{1}(2);
            tuple.spatial_freq = getConstant(rel, 'spatialFreq');
            tuple.stimulus_time = getConstant(rel, 'stimulusTime');
            tuple.post_stimulus_time = getConstant(rel, 'postStimulusTime');
            insert(this, tuple);
            
            % Conditions
            rel = stimulation.StimConditions(key);
            direction = getConditionParam(rel, 'orientation');
            contrast = getConditionParam(rel, 'contrast');
            diskSize = getConditionParam(rel, 'diskSize');
            initialPhase = getConditionParam(rel, 'initialPhase');
            conditions = fetch(rel);
            for i = 1:numel(conditions)
                conditions(i).orientation = mod(direction(i), 180);
                conditions(i).direction = direction(i);
                conditions(i).contrast = contrast(i);
                conditions(i).disk_size = diskSize(i);
                conditions(i).initial_phase = initialPhase(i);
            end
            insert(nc.GratingConditions, conditions);
            
            % Trials
            trials = fetch(stimulation.StimTrials(key));
            condition = getParam(stimulation.StimTrials(key), 'condition', 'UniformOutput', false);
            [trials.condition_num] = deal(condition{:});
            insert(nc.GratingTrials, trials);
        end
    end
end
