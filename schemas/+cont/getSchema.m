function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    acq.getSchema();
    schemaObject = dj.Schema(dj.conn, 'cont', 'cont');
end
obj = schemaObject;
