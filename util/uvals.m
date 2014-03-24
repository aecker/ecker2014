function uvals(rel)
% Display (number of) unique values for each PK field in relation
%   uvals(rel)
%
% AE 2012-12-13

keys = fetch(rel);
if isempty(keys)
    disp('No tuples')
    return
end
fields = rel.primaryKey;
n = numel(fields);
kField = max(cellfun(@length, fields));
kVals = zeros(1, n);
valstr = cell(1, n);
for i = 1 : n
    v = keys(1).(fields{i});
    if ischar(v)
        vals = unique({keys.(fields{i})});
    else
        vals = unique([keys.(fields{i})]);
    end
    kVals(i) = numel(vals);
    v = '';
    for j = 1 : kVals(i)
        if iscell(vals)
            v = [v ', ' vals{j}]; %#ok<*AGROW>
        else
            v = [v ', ' num2str(vals(j))];
        end
    end
    valstr{i} = v(3 : end);
end
kVal = max(fix(log10(kVals))) + 1;
kTotal = get(0, 'CommandWindowSize');
kList = kTotal(1) - kField - kVal - 6;
str = sprintf('%%%ds: %%-%dd (%%s)\n', kField, kVal);
fprintf('\n')
for i = 1 : n
    if numel(valstr{i}) > kList
        v = [valstr{i}(1 : kList - 4) ' ...'];
    else
        v = valstr{i};
    end
    fprintf(str, fields{i}, kVals(i), v);
end
fprintf('\n')
