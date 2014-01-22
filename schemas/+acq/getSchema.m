function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'acq', 'ecker2014_acq');
end
obj = schemaObject;
