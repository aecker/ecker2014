function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    detect.getSchema();
    schemaObject = dj.Schema(dj.conn, 'sort', 'ecker2014_sort');
end
obj = schemaObject;
