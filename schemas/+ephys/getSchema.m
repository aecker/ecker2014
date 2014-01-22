function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    sort.getSchema();
    schemaObject = dj.Schema(dj.conn, 'ephys', 'ecker2014_ephys');
end
obj = schemaObject;
