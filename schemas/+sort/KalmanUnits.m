%{
sort.KalmanUnits (imported) # single units for MoG clustering

-> sort.KalmanFinalize
cluster_number : tinyint unsigned # unit number on this electrode
---
fp             : double           # estimated false positive rate for this cluster
fn             : double           # estimated false negative rate
snr            : double           # signal-to-noise ratio
mean_waveform  : BLOB             # average waveform
%}

classdef KalmanUnits < dj.Relvar
    properties(Constant)
        table = dj.Table('sort.KalmanUnits');
    end
    
    methods 
        function self = KalmanUnits(varargin)
            self.restrict(varargin{:})
        end
        
        function self = makeTuples(self, key, kalmanModel)
            % Detect the selected single units and insert entries for them
             
            [fp, fn, snr, ~] = getStats(kalmanModel);
            
            % Insert references for all the single units
            singleUnits = hasTag(kalmanModel, 'SingleUnit');
            for i = find(singleUnits)
                tuple = key;
                tuple.cluster_number = i;
                
                % Compute mean waveform
                spikeIds = getSpikesByClusIds(kalmanModel,i);
                tuple.mean_waveform = cellfun(@(x) mean(x(:,spikeIds),2), ...
                    kalmanModel.Waveforms.data, 'UniformOutput', false);
                
                tuple.snr = snr(i);
                tuple.fp = fp(i);
                tuple.fn = fn(i);

                insert(sort.KalmanUnits, tuple);
            end
        end
        
        function [spikeTimes, waveform, spikeFile] = getSpikes(self)
            % Gets spike times from the disk.  Should this be stored in the
            % object ?
            assert(count(self) == 1, 'Relvar must be scalar!');
            model = fetch1(sort.KalmanFinalize & self, 'final_model');
            model = MoKsmInterface(model);
            model = uncompress(model);
            model = updateInformation(model);
            [cluster_number waveform spikeFile] = fetchn(self * detect.Electrodes,...
                'cluster_number','mean_waveform','detect_electrode_file');
            spikeFile = spikeFile{1};
            
            spikeTimes = model.SpikeTimes.data(getSpikesByClusIds(model,cluster_number));
        end        
    end
end
