function setPath

base = fileparts(mfilename('fullpath'));
d = dir(base);
d = d([d.isdir]);
d = d(cellfun(@isempty, regexp({d.name}, '^[\+\.](\w*)')));
for i = 1:numel(d)
    addpath(fullfile(base, d(i).name))
end
addpath(base)

% AE ephys lib
addpath(fullfile(base, '../ephyslib'))

% spike sorting lib (Kalman filter model)
addpath(fullfile(base, '../../moksm'))
