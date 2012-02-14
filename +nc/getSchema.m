function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    ephys.getSchema();
    schemaObject = dj.Schema(dj.conn, 'nc', 'aecker');
end
obj = schemaObject;
