function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    detect.getSchema();
    schemaObject = dj.Schema(dj.conn, 'sort', 'sort');
end
obj = schemaObject;
