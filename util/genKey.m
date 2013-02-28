function key = genKey(key, varargin)
% Generate DJ key.
%   key = genKey(key, 'name1', value1, 'name2', value2, ...) augments the
%   given key by the fields/values passed in. These can be either new
%   fields or existing ones, in which case the original values get
%   overridden. If an array of values is passed the individual elements get
%   expanded into an array of keys.
%
% AE 2013-02-21

message = 'Name and value input arguments must come in pairs!';
assert(~mod(length(varargin), 2), message)

% replace fields with variable inputs
for i = 1 : 2 : length(varargin)
    name = varargin{i};
    value = varargin{i + 1};
    assert(ischar(name), message)
    key.(name) = value;
end

% parse out lists
oldkey = key;
fields = fieldnames(key);
for i = 1 : numel(fields)
    name = fields{i};
    value = key(1).(name);
    if numel(value) > 1
        key = dj.struct.join(rmfield(key, name), struct(name, num2cell(value(:))));
    elseif isempty(value)
        key = rmfield(key, name);
        oldkey = rmfield(oldkey, name);
    end
end
key = orderfields(key, oldkey); % restore original order of fields
