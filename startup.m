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

% Dependencies (assumed to be in same base directory as ecker2014
% repository and in folders with their default names)
ndx = find(base == filesep, 1, 'last');
base = base(1 : ndx - 1);
addpath(fullfile(base, 'datajoint-matlab'))
addpath(fullfile(base, 'sessions', 'schemas'))
run(fullfile(base, 'mym', 'mymSetup'))
run(fullfile(base, 'gpfa', 'startup'))
