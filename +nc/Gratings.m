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
trials_per_cond    : int   # min number of trials per condition
total_num_trials   : int   # total number of valid trials
%}

classdef Gratings < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('nc.Gratings');
        popRel = stimulation.StimTrialGroup * ...
            acq.Stimulation('exp_type IN ("GratingExperiment", "AcuteGratingExperiment", "mgrad", "movgrad")');
    end
    
    methods 
        function self = Gratings(varargin)
            self.restrict(varargin{:})
        end
        
        
        function trials = validTrialsCompleteBlocks(self)
            % Returns all valid trials in all completed blocks
            %   This function excludes the last couple of trials if the
            %   last experimental blocks wasn't fully completed (so that
            %   there is an equal number of trials for each condition).
            
            assert(count(self) == 1, 'Relvar must be scalar!')
            nCond = count(nc.GratingConditions & self);
            trialNums = fetchn(self * nc.GratingTrials, 'trial_num', 'ORDER BY trial_num');
            lastTrial = trialNums(fix(numel(trialNums) / nCond) * nCond);
            trials = self * nc.GratingTrials & sprintf('trial_num <= %d', lastTrial);
        end
    end

    methods(Access = protected)
        function makeTuples(this, key)
            
            % catch old legacy datasets
            if any(strcmp(fetch1(acq.Stimulation & key, 'exp_type'), {'mgrad', 'movgrad'}))
                makeTuplesMPI(this, key)
                return
            end
            
            % Grating session
            tuple = key;
            rel = stimulation.StimTrialGroup & key;
            tuple.speed = getConstant(rel, 'speed');
            location = getConstant(rel, 'location', 'UniformOutput', false);
            tuple.location_x = location{1}(1);
            tuple.location_y = location{1}(2);
            tuple.spatial_freq = getConstant(rel, 'spatialFreq');
            tuple.stimulus_time = getConstant(rel, 'stimulusTime');
            try
                tuple.post_stimulus_time = getConstant(rel, 'postStimulusTime');
            catch %#ok
                % some old sessions don't have the postStimulusTime
                % parameter but this was controlled via delayTime
                tmp = fetchn(rel * stimulation.StimTrials, 'trial_params');
                tuple.post_stimulus_time = min(cellfun(@(x) x.delayTime, tmp)) - tuple.stimulus_time;
            end
            
            % Conditions
            rel = stimulation.StimConditions & key;
            direction = getConditionParam(rel, 'orientation');
            contrast = getConditionParam(rel, 'contrast');
            diskSize = getConditionParam(rel, 'diskSize');
            initialPhase = getConditionParam(rel, 'initialPhase');
            conditions = fetch(rel);
            for i = 1 : numel(conditions)
                conditions(i).orientation = mod(direction(i), 180);
                conditions(i).direction = direction(i);
                conditions(i).contrast = contrast(i);
                conditions(i).disk_size = diskSize(i);
                conditions(i).initial_phase = initialPhase(i);
            end
            
            % Trials
            key.valid_trial = true;
            trials = fetch(stimulation.StimTrials & key, 'ORDER BY trial_num');
            condition = getParam(stimulation.StimTrials & key, 'condition', 'UniformOutput', false);
            [trials.condition_num] = deal(condition{:});

            tuple.trials_per_cond = fix(numel(trials) / numel(conditions));
            tuple.total_num_trials = numel(trials);
            
            insert(this, tuple);
            insert(nc.GratingConditions, conditions);
            insert(nc.GratingTrials, trials);
        end
    end
    
    methods (Access = private)
        function makeTuplesMPI(this, key)
            % Import old MPI data (separate to keep makeTuples clean)
            
            expType = fetch1(acq.Stimulation & key, 'exp_type');
            
            % Grating session
            tuple = key;
            rel = stimulation.StimTrialGroup & key;
            tuple.speed = 3.4 * isequal(expType, 'movgrad');
            tuple.location_x = getConstant(rel, 'xOffset');
            tuple.location_y = getConstant(rel, 'yOffset');
            tuple.spatial_freq = 4;
            tuple.stimulus_time = getConstant(rel, 'stimulusTime');
            tuple.post_stimulus_time = 0;
            diskSize = getConstant(rel, 'diskSize');
            
            % Conditions
            rel = stimulation.StimConditions & key;
            direction = getConditionParam(rel, 'orientation');
            contrast = getConditionParam(rel, 'contrast');
            conditions = fetch(rel);
            for i = 1 : numel(conditions)
                conditions(i).orientation = mod(direction(i), 180);
                conditions(i).direction = direction(i);
                conditions(i).contrast = contrast(i);
                conditions(i).disk_size = diskSize;
                conditions(i).initial_phase = 0;
            end
            
            % Trials
            key.valid_trial = true;
            trials = fetch(stimulation.StimTrials & key, 'ORDER BY trial_num');
            condition = getParam(stimulation.StimTrials & key, 'condition', 'UniformOutput', false);
            [trials.condition_num] = deal(condition{:});

            tuple.trials_per_cond = fix(numel(trials) / numel(conditions));
            tuple.total_num_trials = numel(trials);
            
            insert(this, tuple);
            insert(nc.GratingConditions, conditions);
            insert(nc.GratingTrials, trials);
        end
    end
end
