function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    acq.getSchema();
    schemaObject = dj.Schema(dj.conn, 'stimulation', 'stimulation');
end
obj = schemaObject;
