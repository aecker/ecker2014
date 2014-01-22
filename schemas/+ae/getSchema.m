function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    acq.getSchema();
    schemaObject = dj.Schema(dj.conn, 'ae', 'ecker2014_ae');
end
obj = schemaObject;
