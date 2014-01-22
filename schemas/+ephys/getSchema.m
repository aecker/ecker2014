function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    sort.getSchema();
    schemaObject = dj.Schema(dj.conn, 'ephys', 'ephys');
end
obj = schemaObject;
