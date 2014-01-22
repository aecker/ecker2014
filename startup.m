function startup
% Add required folders to path

base = fileparts(mfilename('fullpath'));
d = dir(base);
d = d([d.isdir]);
d = d(cellfun(@isempty, regexp({d.name}, '^[\+\.](\w*)')));
for i = 1:numel(d)
    addpath(fullfile(base, d(i).name))
end
addpath(base)
